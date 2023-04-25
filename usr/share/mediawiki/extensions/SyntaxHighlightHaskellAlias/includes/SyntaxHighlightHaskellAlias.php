<?php

class SyntaxHighlightHaskellAlias
{
  public static function onParserFirstCallInit(Parser &$parser)
  {
    $parser->setHook( 'haskell', [ self::class, 'renderHaskellTag' ] );
    $parser->setHook( 'hask', [ self::class, 'renderHaskTag' ] );
  }

  public static function renderHaskellTag( $input, array $args, Parser $parser, PPFrame $frame )
  {
    $output = $parser->recursiveTagParse( $input, $frame );
    return '<syntaxhighlight lang="haskell">' . $output . '</syntaxhighlight>';
  }

  public static function renderHaskTag( $input, array $args, Parser $parser, PPFrame $frame )
  {
    $output = $parser->recursiveTagParse( $input, $frame );
    return '<syntaxhighlight lang="haskell" inline>' . $output . '</syntaxhighlight>';
  }
}
