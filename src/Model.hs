{-# LANGUAGE DeriveAnyClass             #-}
{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE UndecidableInstances       #-}
{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE TypeOperators              #-}
module Model where

import           Data.Aeson
import Data.Text (Text)
import           Data.Time
import           Data.Typeable (Typeable)
import           Database.Persist
import           Database.Persist.Sqlite
import           Database.Persist.TH
import           GHC.Generics

data Status = Published | Deleted | Draft deriving (Show, Eq, Read, Generic)

instance ToJSON Status

instance FromJSON Status

derivePersistField "Status"

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
BlogEntry
    title String
    contents String
    posted UTCTime
    status Status
    deriving Generic
User
    email Text
    password Text Maybe -- Password may not be set yet
    verkey Text Maybe -- Used for resetting passwords
    verified Bool
    UniqueUser email
    deriving Typeable
|]

instance ToJSON BlogEntry

instance FromJSON BlogEntry
