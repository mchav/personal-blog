{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE ViewPatterns          #-}
module Application where

import Foundation
import Handler.Admin
import Handler.Home
import Handler.Post
import Model

import Control.Monad.Logger
import Database.Persist.Sqlite
import Yesod
import Yesod.Auth

mkYesodDispatch "Blog" resourcesBlog

serve :: IO ()
serve = do
    pool <- runStdoutLoggingT $ createSqlitePool "blog.db3" 10 -- create a new pool
    -- perform any necessary migration
    runSqlPersistMPool (runMigration migrateAll) pool
    warp 3000 (Blog pool "")
