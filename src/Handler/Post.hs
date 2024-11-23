{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
module Handler.Post where

import qualified Data.Text as T
import qualified Text.Julius as J
import qualified Text.Lucius as H
import Data.Aeson
import Data.Maybe
import Data.Time
import Data.Time.Clock
import Data.Time.Clock.POSIX
import Foundation
import Model
import System.Random
import Text.Blaze.Html
import Yesod
import Database.Persist.Sql (toSqlKey)

postPostR :: HandlerFor Blog ()
postPostR = do
    postData <- requireCheckJsonBody :: Handler BlogEntry
    -- check if a post with the same posted time exists
    post <- fmap maybeHead $ liftHandler $ runDB $ selectList [BlogEntryPosted ==. blogEntryPosted postData] []
    case post of
        Nothing -> do
            currentTime <- liftIO getCurrentTime
            let entry = BlogEntry (blogEntryTitle postData) (blogEntryContents postData) currentTime Published
            newId <- runDB $ insert entry
            redirect $ ReadPostR newId
        Just (Entity entryId entry) -> do
            _ <- liftHandler $ runDB $ update entryId [ BlogEntryTitle =. blogEntryTitle postData
                                                      , BlogEntryContents =. blogEntryContents postData
                                                      ]
            redirect $ ReadPostR entryId

maybeHead :: [a] -> Maybe a
maybeHead []     = Nothing
maybeHead (x:xs) = Just x 

getReadPostR :: BlogEntryId -> HandlerFor Blog Html
getReadPostR entryId = defaultLayout $ do
    entry <- liftHandler $ runDB $ get404 entryId
    token <- liftHandler $ fmap reqToken getRequest
    addStylesheetRemote iconsCss
    toWidget $(H.luciusFile "./templates/style.lucius")
    toWidget $(J.juliusFile "./templates/util.julius")
    toWidget $(J.juliusFile "./templates/post_management.julius")
    $(whamletFile "./templates/post.hamlet")

getNewPostR :: HandlerFor Blog Html
getNewPostR = defaultLayout $ do
    let entryId = toSqlKey 0 :: BlogEntryId
    let entry = BlogEntry "" "" (posixSecondsToUTCTime 0) Published
    token <- liftHandler $ fmap reqToken getRequest
    addStylesheetRemote iconsCss
    toWidget $(H.luciusFile "./templates/style.lucius")
    toWidget $(J.juliusFile "./templates/util.julius")
    toWidget $(J.juliusFile "./templates/post_management.julius")
    $(whamletFile "./templates/new_post.hamlet")

getEditPostR :: BlogEntryId -> HandlerFor Blog Html
getEditPostR entryId = defaultLayout $ do
    entry <- liftHandler $ runDB $ get404 entryId
    token <- liftHandler $ fmap reqToken getRequest
    addStylesheetRemote iconsCss
    toWidget $(H.luciusFile "./templates/style.lucius")
    toWidget $(J.juliusFile "./templates/util.julius")
    toWidget $(J.juliusFile "./templates/post_management.julius")
    $(whamletFile "./templates/edit_post.hamlet")
