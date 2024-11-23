{-# LANGUAGE InstanceSigs               #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE ViewPatterns               #-}
{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE UndecidableInstances       #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Foundation where

import Control.Monad            (join)
import Control.Monad.Logger     (runNoLoggingT)
import Data.Maybe               (isJust)
import Database.Persist
import Database.Persist.TH
import Database.Persist.Sqlite
import qualified Data.Text.Lazy.Encoding
import Data.Text as T
import Model
import Network.Mail.Mime
import Text.Blaze.Html.Renderer.Utf8 (renderHtml)
import Text.Hamlet (shamlet)
import Text.Shakespeare.Text 
import Yesod
import Yesod.Auth
import Yesod.Auth.Email


iconsCss :: T.Text
iconsCss = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"

data Blog = Blog {
    -- resources used to connect to the DB
    connPool    :: ConnectionPool,
    baseUrl     :: String
}

instance YesodPersist Blog where
   type YesodPersistBackend Blog = SqlBackend
   runDB f = do
       master <- getYesod
       let pool = connPool master
       runSqlPool f pool

mkYesodData "Blog" $(parseRoutesFile "./config/routes")

instance Yesod Blog where
    yesodMiddleware = defaultCsrfMiddleware . defaultYesodMiddleware

    authRoute _ = Just $ AuthR LoginR

    -- route name, then a boolean indicating if it's a write request
    isAuthorized NewPostR _ = isAdmin
    isAuthorized (EditPostR _) _ = isAdmin

    -- anyone can access other pages
    isAuthorized _ _ = return Authorized

    defaultLayout :: WidgetFor Blog () -> HandlerFor Blog Html
    defaultLayout widget = do
        pc <- widgetToPageContent widget
        withUrlRenderer
            [hamlet|
                $doctype 5
                <html>
                    <head>
                        <title> Michael Chavinda
                        <meta charset=utf-8>
                        <meta name="viewport" content="width=device-width, initial-scale=1.0">
                        <style>body { font-family: Arial, sans-serif; }
                        ^{pageHead pc}
                    <body>
                        ^{pageBody pc}
            |]

isAdmin = do
    mu <- maybeAuthId
    return $ case mu of
        Nothing -> AuthenticationRequired
        -- Hack. Haven't come up with a good auth story yet.
        Just userId -> if (fromSqlKey userId) == 1 then Authorized else Unauthorized "You must be an admin"

instance RenderMessage Blog FormMessage where
    renderMessage _ _ = defaultFormMessage

instance YesodAuth Blog where
    type AuthId Blog = UserId

    loginDest _ = HomeR
    logoutDest _ = HomeR
    authPlugins _ = [authEmail]

    -- Need to find the UserId for the given email address.
    authenticate creds = liftHandler $ runDB $ do
        x <- insertBy $ User (credsIdent creds) Nothing Nothing False
        return $ Authenticated $
            case x of
                Left (Entity userid _) -> userid -- existing user
                Right userid -> userid -- newly added user

instance YesodAuthPersist Blog

-- Refactor and annotate this code. I don't think
-- I understand it well.
instance YesodAuthEmail Blog where
    type AuthEmailId Blog = UserId

    afterPasswordRoute _ = HomeR

    addUnverified email verkey =
        liftHandler $ runDB $ insert $ User email Nothing (Just verkey) False

    sendVerifyEmail email _ verurl = do
        -- Print out to the console the verification email, for easier
        -- debugging.
        liftIO $ putStrLn $ "Copy/ Paste this URL in your browser:" ++ unpack verurl

        -- Send email.
        liftIO $ renderSendMail (emptyMail $ Address Nothing "noreply")
            { mailTo = [Address Nothing email]
            , mailHeaders =
                [ ("Subject", "Verify your email address")
                ]
            , mailParts = [[textPart, htmlPart]]
            }
      where
        textPart = Part
            { partType = "text/plain; charset=utf-8"
            , partEncoding = None
            , partDisposition = DefaultDisposition
            , partContent = PartContent $ Data.Text.Lazy.Encoding.encodeUtf8
                [stext|
                    Please confirm your email address by clicking on the link below.

                    #{verurl}

                    Thank you
                |]
            , partHeaders = []
            }
        htmlPart = Part
            { partType = "text/html; charset=utf-8"
            , partEncoding = None
            , partDisposition = DefaultDisposition
            , partContent = PartContent $ renderHtml
                [shamlet|
                    <p>Please confirm your email address by clicking on the link below.
                    <p>
                        <a href=#{verurl}>#{verurl}
                    <p>Thank you
                |]
            , partHeaders = []
            }
    getVerifyKey = liftHandler . runDB . fmap (join . fmap userVerkey) . get
    setVerifyKey uid key = liftHandler $ runDB $ update uid [UserVerkey =. Just key]
    verifyAccount uid = liftHandler $ runDB $ do
        mu <- get uid
        case mu of
            Nothing -> return Nothing
            Just u -> do
                update uid [UserVerified =. True, UserVerkey =. Nothing]
                return $ Just uid
    getPassword = liftHandler . runDB . fmap (join . fmap userPassword) . get
    setPassword uid pass = liftHandler . runDB $ update uid [UserPassword =. Just pass]
    getEmailCreds email = liftHandler $ runDB $ do
        mu <- getBy $ UniqueUser email
        case mu of
            Nothing -> return Nothing
            Just (Entity uid u) -> return $ Just EmailCreds
                { emailCredsId = uid
                , emailCredsAuthId = Just uid
                , emailCredsStatus = isJust $ userPassword u
                , emailCredsVerkey = userVerkey u
                , emailCredsEmail = email
                }
    getEmail = liftHandler . runDB . fmap (fmap userEmail) . get
