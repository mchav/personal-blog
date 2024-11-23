{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
module Handler.Home where

import qualified Data.Text as T
import qualified Text.Julius as J
import qualified Text.Lucius as H
import Foundation
import Model
import Text.Blaze.Html
import Yesod


getHomeR :: HandlerFor Blog Html
getHomeR = defaultLayout $ do
    -- change
    entries <- liftHandler $ runDB $ selectList [] [Desc BlogEntryPosted]
    addStylesheetRemote iconsCss
    toWidget $(H.luciusFile "./templates/style.lucius")
    toWidget $(J.juliusFile "./templates/util.julius" )
    $(whamletFile "./templates/index.hamlet")
