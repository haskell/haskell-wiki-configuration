# Syntax highlighting tag alias for Haskell

This extension adds ability to use `<haskell></haskell>` and `<hask></hask>` to highlight blocks of Haskell code.
The functionality of this extension relies on SyntaxHighlight_GeSHi module.

## Running the tests

The extension contains standard Mediawiki parser tests placed in tests/parser/parserTests.txt directory.

To execute them, run this command in the root directory of your Mediawiki installation:
```
php tests/parser/parserTests.php --file={your_extensions_directory_path}/SyntaxHighlight_GeSHi_HaskellAlias/tests/parser/parserTests.txt
```
