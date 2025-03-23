# unihan.nvim

漢字 LanguageServer

https://github.com/ousttrue/neoskk

から分離。

いつのまにか路線が変って漢文読み向けに変化してきた。

## feature

### completion

カーソルの左の文字を変換できる。
カーソルを `^` であらわす。

ひらがな

```
▽かんじ^
 => 漢字
```

ひらがな + おくりがな

```
▽おく▽り^
 => 送り
```

```
▽おく▽r^
 => 送r
```

四角号碼

```
▽6666^
 => 器
```

注音符号

```
ㄏㄢ^
 => 漢
```

LSP Completion の TextEdit で Completion 開始位置より遡って置換する。
この `TextEdit で Completion 開始位置より遡` が nvim-cmp と相性が悪い。
vim.lsp.completion は動く。

### hover

単漢字の情報を表示する(漢文)。

## impl

none-ls を参考に、 nvim lua の関数 callback で LanguageServer を実装している。

- [ ] 選択結果を記録して、次回上位に来るようにしたい
- [ ] ▽マーカーの検出ロジック
- [ ] 送りかなの auto completion 発動
- [ ] 送りかなの促音
- [ ] 小韻から漢音を導出する
- [ ] 簡体字 <=> 繁体字
- [ ] 新字体 <=> 繁体字
- [ ] その他異字体

## 辞書情報

### Unicode

単漢字は、 Unicode のデータベースが便利です。
かな、pinyin、四角号碼などの情報があります。
むしろ、変換候補が多くなりすぎるので、適当に減らす必用あり。

- https://www.unicode.org/Public/UNIDATA/

  - Blocks.txt
  - UnicodeData.txt

- https://www.unicode.org/reports/tr38/
- https://www.unicode.org/Public/UCD/latest/ucd/

  - https://www.unicode.org/Public/UCD/latest/ucd/Unihan.zip
    - Unihan_DictionaryLikeData.txt 四角号碼 etc...
    - Unihan_Readings.txt かな, pinyin, 反切 etc...
    - Unihan_Variants.txt 異字体, kSimplifiedVariant, kTraditionalVariant

- https://www.unicode.org/Public/emoji/1.0/emoji-data.txt

### SKK

単語や送りがなつきはこちら。

- http://openlab.ring.gr.jp/skk/wiki/wiki.cgi?page=SKK%BC%AD%BD%F1
- https://github.com/skk-dict/jisyo

### 常用漢字

- [簡体字、日用字変換の手順](http://mikeo410.minim.ne.jp/%EF%BC%95%EF%BC%8E%E3%80%8C%E3%81%8B%E3%81%9F%E3%81%A1%E3%80%8D%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6/%EF%BC%91%EF%BC%8E%E6%96%87%E5%AD%97/%EF%BC%91%EF%BC%8E%E7%B0%A1%E4%BD%93%E5%AD%97/%EF%BC%91%EF%BC%8E%E7%B0%A1%E4%BD%93%E5%AD%97%E3%80%81%E6%97%A5%E7%94%A8%E5%AD%97%E5%A4%89%E6%8F%9B%E3%81%AE%E6%89%8B%E9%A0%86.html)
- https://x0213.org/joyo-kanji-code/
- https://github.com/rime-aca/character_set
- https://www.aozora.gr.jp/kanji_table/

- https://github.com/zispace/hanzi-chars
  - https://github.com/zispace/hanzi-chars/blob/main/data-charlist/%E6%97%A5%E6%9C%AC%E3%80%8A%E5%B8%B8%E7%94%A8%E6%BC%A2%E5%AD%97%E8%A1%A8%E3%80%8B%EF%BC%882010%E5%B9%B4%EF%BC%89%E6%97%A7%E5%AD%97%E4%BD%93.txt

### 漢字

漢文。

- WEB支那漢 日本語音訓
  - https://www.seiwatei.net/info/dnchina.htm
- https://github.com/cjkvi/cjkvi-dict

  - 學生字典 Text Data (xszd.txt)

- https://github.com/rime-aca/character_set

- [有女同車《〈廣韻〉全字表》原表](https://github.com/syimyuzya/guangyun0704)
- `影印本` https://github.com/kanripo/KR1j0054
- https://github.com/rime-aca/rime-middle-chinese-phonetics?tab=readme-ov-file
- https://github.com/sozysozbot/zyegnio_xrynmu/tree/master
- https://ytenx.org/
- https://github.com/pujdict/pujdict

玉篇

- https://www.kanripo.org/
- https://github.com/kanripo/KR1j0056
- https://github.com/kanripo/KR1j0022

- https://github.com/g0v/moedict-app

### pinyin

- https://github.com/ZSaberLv0/ZFVimIM_pinyin_base/tree/master/misc
- https://github.com/ZSaberLv0/ZFVimIM_pinyin/tree/master/misc

- https://github.com/fxsjy/jieba
