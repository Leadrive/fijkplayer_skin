
# fijkplayer_skin
[![pub package](https://img.shields.io/pub/v/fijkplayer_skin.svg)](https://pub.dev/packages/fijkplayer_skin)

这是一款 fijkplayer 播放器的普通皮肤，主要解决 fijkplayer 自带的皮肤不好看，没有手势拖动快进，快退
fijkplayer_skin只是一款皮肤，并不是播放器，所以 fijkplayer 存在的问题，这里 fijkplayer_skin 一样存在

## 使用说明

在使用皮肤之前，你需要查看 fijkplayer 的文档说明，了解如何 fijkplayer [自定义UI](https://fijkplayer.befovy.com/docs/zh/custom-ui.html#gsc.tab=0)

## 预览
<img style="max-width: 100%;" src="https://cdn.jsdelivr.net/gh/abcd498936590/pic@master/img/fijkplayer_skin-1.png" />

## Dart-Cms-Manage（后台）

[后台管理系统部分(使用vue全家桶)](https://github.com/abcd498936590/Dart-Cms-Manage)

## Dart-Cms-Flutter（安卓）

[安卓APP使用google flutter技术开发](https://github.com/abcd498936590/Dart-Cms-Flutter)


## 安装
pubspec.yaml
```yaml
dependencies:
  fijkplayer_skin: ${lastes_version}
```

## 使用示例
```dart
    # 引入 fijkplayer_skin
    import 'package:fijkplayer_skin/fijkplayer_skin.dart';
    # 引入 fijkplayer
    import 'package:fijkplayer/fijkplayer.dart';


    class VideoScreen extends StatefulWidget {
      final String url;

      VideoScreen({@required this.url});

      @override
      _VideoScreenState createState() => _VideoScreenState();
    }

    class _VideoScreenState extends State<VideoScreen> {
      final FijkPlayer player = FijkPlayer();

      _VideoScreenState();

      @override
      void initState() {
        super.initState();
        player.setDataSource(widget.url, autoPlay: true);
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: Text("Fijkplayer Example")),
            body: Container(
              alignment: Alignment.center,
              # 这里 FijkView 开始为自定义 UI 部分
              child: FijkView(
                height: 240,
                color: Colors.black,
                fit: FijkFit.cover,
                player: player,
                panelBuilder: (
                  FijkPlayer player,
                  FijkData data,
                  BuildContext context,
                  Size viewSize,
                  Rect texturePos,
                ) {
                 /// 使用自定义的布局
                 return CustomFijkPanel(
                   player: player,
                   # 传递 context 用于左上角返回箭头关闭当前页面，不要传递错误 context，
                   # 如果要点击箭头关闭当前的页面，那必须传递当前页面的根 context
                   buildContext: context,
                   viewSize: viewSize,
                   texturePos: texturePos,
                   # 标题 当前页面顶部的标题部分
                   playerTitle: "标题",
                 );
              },
             );
          )
        );
      }

      @override
      void dispose() {
        super.dispose();
        player.release();
      }
    }

```

## LICENSE
MIT
