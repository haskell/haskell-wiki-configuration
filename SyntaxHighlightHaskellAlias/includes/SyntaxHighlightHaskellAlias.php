<?php

class SyntaxHighlightHaskellAlias
{
  public static function onParserFirstCallInit(Parser $parser)
  {
    $parser->setHook( 'haskell', [ self::class, 'renderHaskellTag' ] );
    $parser->setHook( 'hask', [ self::class, 'renderHaskTag' ] );
  }

  public static function renderHaskellTag( $input, array $args, Parser $parser, PPFrame $frame )
  {
    $output = '<hask />' . $parser->recursiveTagParse( '<syntaxhighlight lang="haskell">' . $input . '</syntaxhighlight>', $frame );
    return $output;
  }

  public static function renderHaskTag( $input, array $args, Parser $parser, PPFrame $frame )
  {
    $output = '<hask />' . $parser->recursiveTagParse( '<syntaxhighlight lang="haskell" inline>' . $input . '</syntaxhighlight>', $frame );
    return $output;
  }
}
