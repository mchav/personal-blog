{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
module Handler.Home where

import qualified Data.Text as T
import Foundation
import Yesod

name :: T.Text
name = "Michael"

getHomeR :: HandlerFor Blog Html
getHomeR = defaultLayout [whamlet|
        Hello #{name}!
    |]
