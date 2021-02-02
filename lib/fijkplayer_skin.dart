import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}

class CustomFijkPanel extends StatefulWidget {
  final FijkPlayer player;
  final BuildContext buildContext;
  final Size viewSize;
  final Rect texturePos;
  final BuildContext pageContent;
  final String playerTitle;

  CustomFijkPanel({
    @required this.player,
    this.buildContext,
    this.viewSize,
    this.texturePos,
    this.pageContent,
    this.playerTitle,
  });

  @override
  _CustomFijkPanelState createState() => _CustomFijkPanelState();
}

class _CustomFijkPanelState extends State<CustomFijkPanel> {
  FijkPlayer get player => widget.player;

  Duration _duration = Duration();
  Duration _currentPos = Duration();
  Duration _bufferPos = Duration();
  // 滑动后值
  Duration _dargPos = Duration();

  bool _isTouch = false;

  bool _playing = false;
  bool _prepared = false;
  String _exception;

  num startPosX = null;
  num startPosY = null;
  Size playerBoxSize;

  // bool _buffering = false;

  double _seekPos = -1.0;

  StreamSubscription _currentPosSubs;

  StreamSubscription _bufferPosSubs;
  //StreamSubscription _bufferingSubs;

  Timer _hideTimer;
  bool _hideStuff = true;
  bool _lockStuff = true;

  double _volume = 1.0;

  final barHeight = 50.0;

  @override
  void initState() {
    super.initState();

    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;
    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;
    _exception = player.value.exception.message;
    // _buffering = player.isBuffering;

    player.addListener(_playerValueChanged);

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
      });
    });

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      setState(() {
        _bufferPos = v;
      });
    });
  }

// +++++++++++++++++++++++++++++++++++++++++++

  _onHorizontalDragStart(detills) {
    startPosX = detills.globalPosition.dx;
  }

  _onHorizontalDragUpdate(detills) {
    _isTouch = true;
    num curXpost = detills.globalPosition.dx;
    //
    if (curXpost < 0) {
      return null;
    }
    //
    double dragRange = (curXpost - startPosX) + _currentPos.inSeconds;
    if (dragRange < 0) {
      dragRange = 0;
    }
    int lastSecond = _duration.inSeconds;
    if (dragRange > lastSecond) {
      dragRange = lastSecond.toDouble();
    }
    _dargPos = Duration(seconds: dragRange.toInt());
  }

  _onHorizontalDragEnd(detills) {
    player.seekTo(_dargPos.inMilliseconds);
    _isTouch = false;
  }

// +++++++++++++++++++++++++++++++++++++++++++

  void _playerValueChanged() {
    FijkValue value = player.value;
    if (value.duration != _duration) {
      setState(() {
        _duration = value.duration;
      });
    }

    bool playing = (value.state == FijkState.started);
    bool prepared = value.prepared;
    String exception = value.exception.message;
    if (playing != _playing ||
        prepared != _prepared ||
        exception != _exception) {
      setState(() {
        _playing = playing;
        _prepared = prepared;
        _exception = exception;
      });
    }
  }

  void _playOrPause() {
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _hideTimer?.cancel();

    player.removeListener(_playerValueChanged);
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _startHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  void _changePlayerLockState() {
    setState(() {
      _lockStuff = !_lockStuff;
      _cancelAndRestartTimer();
    });
  }

  // 底部控制栏 - 播放按钮
  Widget _buildPlayStateBtn() {
    IconData iconData = _playing ? Icons.pause : Icons.play_arrow;

    return IconButton(
      icon: Icon(iconData),
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 10.0,
        right: 10.0,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onPressed: _playOrPause,
    );
  }

  // 控制器ui 底部
  AnimatedOpacity _buildBottomBar(BuildContext context) {
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue =
        _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 0.8,
      duration: Duration(milliseconds: 400),
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            colors: [
              Color.fromRGBO(0, 0, 0, 0),
              Color.fromRGBO(0, 0, 0, 0.7),
            ],
          ),
        ),
        child: Row(
          children: <Widget>[
            // 按钮 - 播放/暂停
            _buildPlayStateBtn(),
            // 已播放时间
            Padding(
              padding: EdgeInsets.only(right: 5.0, left: 5),
              child: Text(
                '${_duration2String(_currentPos)}',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
              ),
            ),
            // 播放进度 if 没有开始播放 占满，空ui， else fijkSlider widget
            _duration.inMilliseconds == 0
                ? Expanded(child: Center())
                : Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 5, left: 5),
                      child: FijkSlider(
                        colors: FijkSliderColors(
                          cursorColor: Theme.of(context).accentColor,
                          playedColor: Theme.of(context).accentColor,
                        ),
                        value: currentValue,
                        cacheValue: _bufferPos.inMilliseconds.toDouble(),
                        min: 0.0,
                        max: duration,
                        onChanged: (v) {
                          _startHideTimer();
                          setState(() {
                            _seekPos = v;
                          });
                        },
                        onChangeEnd: (v) {
                          setState(() {
                            player.seekTo(v.toInt());
                            print("seek to $v");
                            _currentPos =
                                Duration(milliseconds: _seekPos.toInt());
                            _seekPos = -1;
                          });
                        },
                      ),
                    ),
                  ),

            // 总播放时间
            _duration.inMilliseconds == 0
                ? Container(child: const Text("LIVE"))
                : Padding(
                    padding: EdgeInsets.only(right: 5.0, left: 5),
                    child: Text(
                      '${_duration2String(_duration)}',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
            // 按钮 - 全屏/退出全屏
            IconButton(
              icon: Icon(widget.player.value.fullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen),
              padding: EdgeInsets.only(left: 10.0, right: 10.0),
              color: Colors.white,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onPressed: () {
                widget.player.value.fullScreen
                    ? player.exitFullScreen()
                    : player.enterFullScreen();
              },
            )
            //
          ],
        ),
      ),
    );
  }

  // 播放器顶部 返回 + 标题
  Widget _buildTopBar() {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 0.8,
      duration: Duration(milliseconds: 400),
      child: Container(
        height: barHeight,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            colors: [
              Color.fromRGBO(0, 0, 0, 0.7),
              Color.fromRGBO(0, 0, 0, 0),
            ],
          ),
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.arrow_back),
              padding: EdgeInsets.only(
                left: 10.0,
                right: 10.0,
              ),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              color: Colors.white,
              onPressed: () {
                // 判断当前是否全屏，如果全屏，退出
                if (widget.player.value.fullScreen) {
                  player.exitFullScreen();
                } else {
                  player.stop();
                  Navigator.pop(context);
                }
              },
            ),
            Expanded(
              child: Container(
                child: widget.playerTitle != null
                    ? Text(
                        widget.playerTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }

  // 居中播放按钮
  Widget _buildCenterPlayBtn() {
    return Container(
      color: Colors.transparent,
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: _exception != null
            ? Text(
                _exception,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                ),
              )
            : (_prepared || player.state == FijkState.initialized)
                ? AnimatedOpacity(
                    opacity: _hideStuff ? 0.0 : 0.7,
                    duration: Duration(milliseconds: 400),
                    child: IconButton(
                        iconSize: barHeight * 1.2,
                        icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
                            color: Colors.white),
                        padding: EdgeInsets.only(left: 10.0, right: 10.0),
                        onPressed: _playOrPause),
                  )
                : SizedBox(
                    width: barHeight,
                    height: barHeight,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = player.value.fullScreen
        ? Rect.fromLTWH(
            0,
            0,
            widget.viewSize.width,
            widget.viewSize.height,
          )
        : Rect.fromLTRB(
            max(0.0, widget.texturePos.left),
            max(0.0, widget.texturePos.top),
            min(widget.viewSize.width, widget.texturePos.right),
            min(widget.viewSize.height, widget.texturePos.bottom),
          );
    return WillPopScope(
      child: Positioned.fromRect(
        rect: rect,
        child: GestureDetector(
          onTap: _cancelAndRestartTimer,
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: AbsorbPointer(
            absorbing: _hideStuff && _lockStuff,
            child: Column(
              children: <Widget>[
                // 播放器顶部控制器
                _buildTopBar(),
                // 中间按钮
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _cancelAndRestartTimer();
                    },
                    child: Container(
                      child: Stack(
                        children: <Widget>[
                          Align(
                            alignment: Alignment.topCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 显示快进时间的块
                                _isTouch
                                    ? Container(
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(5),
                                          ),
                                          color: Color.fromRGBO(0, 0, 0, 0.8),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: 10, right: 10),
                                          child: Text(
                                            '${_duration2String(_dargPos)}/${_duration2String(_duration)}',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      )
                                    : Container()
                              ],
                            ),
                          ),
                          // 中间按钮
                          Align(
                            alignment: Alignment.center,
                            child: _buildCenterPlayBtn(),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                // 播放器底部控制器
                _buildBottomBar(context),
              ],
            ),
          ),
        ),
      ),
      onWillPop: () async {
        if (!widget.player.value.fullScreen) widget.player.stop();
        return true;
      },
    );
  }
}
