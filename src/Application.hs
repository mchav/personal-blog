{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
module Application where

import Foundation
import Handler.Admin
import Handler.Home
import Yesod

mkYesodDispatch "Blog" resourcesBlog

main :: IO ()
main = warp 3000 Blog
