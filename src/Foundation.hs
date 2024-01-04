{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE QuasiQuotes           #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}
module Foundation where

import qualified Data.Text as T
import Yesod

data Blog = Blog

mkYesodData "Blog" $(parseRoutesFile "./config/routes")

instance Yesod Blog
