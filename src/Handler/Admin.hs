{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
module Handler.Admin where

import qualified Data.Text as T
import Foundation
import Yesod

name :: T.Text
name = "Michael"

getAdminR :: HandlerFor Blog Html
getAdminR = defaultLayout [whamlet|
        Hello, admin #{name}!
    |]
