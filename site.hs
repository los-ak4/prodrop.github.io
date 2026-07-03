--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Data.List (intercalate)
import           Hakyll
import           Main.Utf8


--------------------------------------------------------------------------------
main :: IO ()
main = withUtf8 $ do  -- to solve unicode problems
    hakyllWith config $ do
        match "images/*" $ do
            route   idRoute
            compile copyFileCompiler

        match "css/*" $ do
            route   idRoute
            compile compressCssCompiler

        match (fromList ["contact.markdown"]) $ do
            route   $ setExtension "html"
            compile $ pandocCompiler
                >>= loadAndApplyTemplate "templates/default.html" defaultContext
                >>= relativizeUrls
        
        match "law/*" $ do
            route $ setExtension "html"
            compile $ pandocCompiler
                >>= loadAndApplyTemplate "templates/law.html"    lawCtx
                >>= loadAndApplyTemplate "templates/default.html" lawCtx
                >>= relativizeUrls

        match "index.html" $ do
            route idRoute
            compile $ do
                laws <- recentFirst =<< loadAll "law/*"
                let indexCtx =
                        listField "law" lawCtx (return laws) `mappend`
                        defaultContext

                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
lawCtx :: Context String
lawCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration
  { destinationDirectory = "docs"
  , deployCommand = intercalate " && "
        [ "git add ."
        , "set /p msg = \"Commit message? \""
        , "git commit -m %msg%"
        , "git push"
        ]
  }