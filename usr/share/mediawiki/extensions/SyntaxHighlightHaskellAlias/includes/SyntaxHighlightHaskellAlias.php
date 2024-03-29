<?php

class SyntaxHighlightHaskellAliasHooks
{
    public static function onParserFirstCallInit(Parser &$parser)
    {
        $parser->setHook('haskell', [self::class, 'haskellKeywordHook']);
        $parser->setHook('hask', [self::class, 'haskKeywordHook']);
    }

    public static function haskellKeywordHook($text, $args = array(), $parser)
    {
        $args['lang'] = 'haskell';
        return SyntaxHighlight_GeSHi::parserHook($text, $args, $parser);
    }

    public static function haskKeywordHook($text, $args = array(), $parser)
    {
        $args['lang'] = 'haskell';
        $args['enclose'] = 'none';
        $out = SyntaxHighlight_GeSHi::parserHook($text, $args, $parser);
        return '<span class="inline-code">' . $out . '</span>';
    }
}

