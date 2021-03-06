import 'dart:io';
import 'package:Prism/data/pexels/provider/pexels.dart';
import 'package:Prism/data/prism/provider/prismProvider.dart';
import 'package:Prism/data/wallhaven/provider/wallhaven.dart';
import 'package:Prism/routes/router.dart';
import 'package:Prism/routes/routing_constants.dart';
import 'package:Prism/theme/jam_icons_icons.dart';
import 'package:Prism/ui/widgets/animated/loader.dart';
import 'package:Prism/ui/widgets/clockOverlay.dart';
import 'package:Prism/ui/widgets/menuButton/downloadButton.dart';
import 'package:Prism/ui/widgets/menuButton/favWallpaperButton.dart';
import 'package:Prism/ui/widgets/menuButton/setWallpaperButton.dart';
import 'package:Prism/ui/widgets/menuButton/shareButton.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:screenshot/screenshot.dart';
import 'package:tutorial_coach_mark/animated_focus_light.dart';
import 'package:tutorial_coach_mark/target_position.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:Prism/main.dart' as main;
import 'package:Prism/global/globals.dart' as globals;

class WallpaperScreen extends StatefulWidget {
  final List arguments;
  WallpaperScreen({@required this.arguments});
  @override
  _WallpaperScreenState createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen>
    with SingleTickerProviderStateMixin {
  Future<bool> onWillPop() async {
    if (navStack.length > 1) navStack.removeLast();
    print(navStack);
    return true;
  }

  bool isNew;
  List<TargetFocus> targets = List();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String provider;
  int index;
  String link;
  AnimationController shakeController;
  bool isLoading = true;
  PaletteGenerator paletteGenerator;
  List<Color> colors;
  Color accent;
  bool colorChanged = false;
  File _imageFile;
  bool screenshotTaken = false;
  ScreenshotController screenshotController = ScreenshotController();
  PanelController panelController = PanelController();
  bool panelClosed = true;

  Future<void> _updatePaletteGenerator() async {
    setState(() {
      isLoading = true;
    });
    paletteGenerator = await PaletteGenerator.fromImageProvider(
      new NetworkImage(link),
      maximumColorCount: 20,
    );
    setState(() {
      isLoading = false;
    });
    colors = paletteGenerator.colors.toList();
    if (paletteGenerator.colors.length > 5) {
      colors = colors.sublist(0, 5);
    }
    setState(() {
      accent = colors[0];
    });
  }

  void updateAccent() {
    if (colors.contains(accent)) {
      var index = colors.indexOf(accent);
      setState(() {
        accent = colors[(index + 1) % 5];
      });
      setState(() {
        colorChanged = true;
      });
    }
  }

  void initTargets() {
    targets.add(TargetFocus(
      identify: "Target 0",
      targetPosition: TargetPosition(Size(0, 0), Offset(0, 0)),
      contents: [
        ContentTarget(
            align: AlignContent.bottom,
            child: SizedBox(
              height: globals.height,
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Variants are here.",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: RichText(
                        text: TextSpan(
                            text: "➡ Tap to quickly cycle between ",
                            style: TextStyle(color: Colors.white),
                            children: [
                              TextSpan(
                                text: "color variants ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: "of the wallpaper.\n\n"),
                              TextSpan(text: "➡ Press and hold to "),
                              TextSpan(
                                text: "reset ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: "the variant.\n\n"),
                              TextSpan(
                                  text:
                                      "➡ To download and set variants of a wallpaper, you need to be a "),
                              TextSpan(
                                text: "premium ",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: "user."),
                            ]),
                      ),
                    )
                  ],
                ),
              ),
            ))
      ],
      shape: ShapeLightFocus.Circle,
    ));
  }

  void showTutorial() {
    TutorialCoachMark(context,
        targets: targets,
        colorShadow: Color(0xFFE57697),
        textSkip: "SKIP",
        paddingFocus: 1,
        opacityShadow: 0.9, finish: () {
      print("finish");
    }, clickTarget: (target) {
      print(target.identify);
    }, clickSkip: () {
      print("skip");
    })
      ..show();
  }

  void afterLayout(_) {
    var newApp2 = main.prefs.get("newApp2");
    if (newApp2 == null || newApp2 == true) {
      Future.delayed(Duration(milliseconds: 100), showTutorial);
      main.prefs.put("newApp2", false);
    } else {
      main.prefs.put("newApp2", false);
    }
  }

  @override
  void initState() {
    // print("Wallpaper Screen");
    shakeController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    isNew = true;
    super.initState();
    initTargets();
    if (isNew) {
      Future.delayed(Duration(seconds: 0)).then(
          (value) => WidgetsBinding.instance.addPostFrameCallback(afterLayout));
    }
    SystemChrome.setEnabledSystemUIOverlays([]);
    provider = widget.arguments[0];
    index = widget.arguments[1];
    link = widget.arguments[2];
    isLoading = true;
    _updatePaletteGenerator();
  }

  void UnsecureWindow() async {
    await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    print("Disabled Secure flags");
  }

  @override
  void dispose() {
    super.dispose();
    shakeController.dispose();
    UnsecureWindow();
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
  }

  @override
  Widget build(BuildContext context) {
    // try {
    final Animation<double> offsetAnimation = Tween(begin: 0.0, end: 48.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(shakeController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              shakeController.reverse();
            }
          });
    return WillPopScope(
      onWillPop: onWillPop,
      child: provider == "WallHaven"
          ? Scaffold(
              resizeToAvoidBottomPadding: false,
              key: _scaffoldKey,
              backgroundColor:
                  isLoading ? Theme.of(context).primaryColor : accent,
              body: SlidingUpPanel(
                onPanelOpened: () {
                  if (panelClosed) {
                    print('Screenshot Starting');
                    setState(() {
                      panelClosed = false;
                    });
                    screenshotController
                        .capture(
                      pixelRatio: 3,
                      delay: Duration(milliseconds: 10),
                    )
                        .then((File image) async {
                      setState(() {
                        _imageFile = image;
                        screenshotTaken = true;
                      });
                      print('Screenshot Taken');
                    }).catchError((onError) {
                      print(onError);
                    });
                  }
                },
                onPanelClosed: () {
                  setState(() {
                    panelClosed = true;
                  });
                },
                backdropEnabled: true,
                backdropTapClosesPanel: true,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [],
                collapsed: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Color(0xFF2F2F2F)),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 20,
                    child: Center(
                        child: Icon(
                      JamIcons.chevron_up,
                      color: Colors.white,
                    )),
                  ),
                ),
                minHeight: MediaQuery.of(context).size.height / 20,
                parallaxEnabled: true,
                parallaxOffset: 0.54,
                color: Color(0xFF2F2F2F),
                maxHeight: MediaQuery.of(context).size.height * .46,
                controller: panelController,
                panel: Container(
                  height: MediaQuery.of(context).size.height * .46,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: Color(0xFF2F2F2F),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          JamIcons.chevron_down,
                          color: Colors.white,
                        ),
                      )),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            colors == null ? 5 : colors.length,
                            (color) {
                              return GestureDetector(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colors == null
                                          ? Color(0xFF000000)
                                          : colors[color],
                                      borderRadius: BorderRadius.circular(500),
                                    ),
                                    height:
                                        MediaQuery.of(context).size.width / 8,
                                    width:
                                        MediaQuery.of(context).size.width / 8,
                                  ),
                                  onTap: () {
                                    navStack.removeLast();
                                    print(navStack);
                                    SystemChrome.setEnabledSystemUIOverlays([
                                      SystemUiOverlay.top,
                                      SystemUiOverlay.bottom
                                    ]);
                                    Future.delayed(Duration(seconds: 0)).then(
                                        (value) =>
                                            Navigator.pushReplacementNamed(
                                              context,
                                              ColorRoute,
                                              arguments: [
                                                colors[color]
                                                    .toString()
                                                    .replaceAll(
                                                        "Color(0xff", "")
                                                    .replaceAll(")", ""),
                                              ],
                                            ));
                                  });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(35, 0, 35, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 5, 0, 10),
                                    child: Text(
                                      Provider.of<WallHavenProvider>(context,
                                              listen: false)
                                          .walls[index]
                                          .id
                                          .toString()
                                          .toUpperCase(),
                                      style:
                                          Theme.of(context).textTheme.bodyText1,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        JamIcons.eye,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "${Provider.of<WallHavenProvider>(context, listen: false).walls[index].views.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        JamIcons.heart_f,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "${Provider.of<WallHavenProvider>(context, listen: false).walls[index].favourites.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(
                                        JamIcons.save,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "${double.parse(((double.parse(Provider.of<WallHavenProvider>(context, listen: false).walls[index].file_size.toString()) / 1000000).toString())).toStringAsFixed(2)} MB",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    child: Row(
                                      children: [
                                        Text(
                                          Provider.of<WallHavenProvider>(
                                                      context,
                                                      listen: false)
                                                  .walls[index]
                                                  .category
                                                  .toString()[0]
                                                  .toUpperCase() +
                                              Provider.of<WallHavenProvider>(
                                                      context,
                                                      listen: false)
                                                  .walls[index]
                                                  .category
                                                  .toString()
                                                  .substring(1),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText2,
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          JamIcons.unordered_list,
                                          size: 20,
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        "${Provider.of<WallHavenProvider>(context, listen: false).walls[index].resolution.toString()}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        JamIcons.set_square,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                        provider.toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText2,
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        JamIcons.database,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            DownloadButton(
                                colorChanged: colorChanged,
                                link: screenshotTaken
                                    ? _imageFile.path
                                    : Provider.of<WallHavenProvider>(context,
                                            listen: false)
                                        .walls[index]
                                        .path
                                        .toString()),
                            SetWallpaperButton(
                                colorChanged: colorChanged,
                                url: screenshotTaken
                                    ? _imageFile.path
                                    : Provider.of<WallHavenProvider>(context)
                                        .walls[index]
                                        .path),
                            FavouriteWallpaperButton(
                              id: Provider.of<WallHavenProvider>(context,
                                      listen: false)
                                  .walls[index]
                                  .id
                                  .toString(),
                              provider: "WallHaven",
                              wallhaven: Provider.of<WallHavenProvider>(context,
                                      listen: false)
                                  .walls[index],
                              trash: false,
                            ),
                            ShareButton(
                                id: Provider.of<WallHavenProvider>(context,
                                        listen: false)
                                    .walls[index]
                                    .id,
                                provider: provider,
                                url: Provider.of<WallHavenProvider>(context,
                                        listen: false)
                                    .walls[index]
                                    .path,
                                thumbUrl: Provider.of<WallHavenProvider>(
                                        context,
                                        listen: false)
                                    .walls[index]
                                    .thumbs["original"])
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                body: Stack(
                  children: <Widget>[
                    AnimatedBuilder(
                        animation: offsetAnimation,
                        builder: (buildContext, child) {
                          if (offsetAnimation.value < 0.0)
                            print('${offsetAnimation.value + 8.0}');
                          return GestureDetector(
                            child: CachedNetworkImage(
                              imageUrl: Provider.of<WallHavenProvider>(context)
                                  .walls[index]
                                  .path,
                              imageBuilder: (context, imageProvider) =>
                                  Screenshot(
                                controller: screenshotController,
                                child: Container(
                                  margin: EdgeInsets.symmetric(
                                      vertical: offsetAnimation.value * 1.25,
                                      horizontal: offsetAnimation.value / 2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        offsetAnimation.value),
                                    image: DecorationImage(
                                      colorFilter: colorChanged
                                          ? ColorFilter.mode(
                                              accent, BlendMode.hue)
                                          : null,
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              placeholder: (context, url) => Stack(
                                children: <Widget>[
                                  SizedBox.expand(child: Text("")),
                                  Container(
                                    child: Center(
                                      child: Loader(),
                                    ),
                                  ),
                                ],
                              ),
                              errorWidget: (context, url, error) => Container(
                                child: Center(
                                  child: Icon(
                                    JamIcons.close_circle_f,
                                    color: isLoading
                                        ? Theme.of(context).accentColor
                                        : accent.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            onPanUpdate: (details) {
                              if (details.delta.dy < -10) {
                                panelController.open();
                                HapticFeedback.vibrate();
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                colorChanged = false;
                              });
                              HapticFeedback.vibrate();
                              shakeController.forward(from: 0.0);
                            },
                            onTap: () {
                              HapticFeedback.vibrate();
                              !isLoading ? updateAccent() : print("");
                              shakeController.forward(from: 0.0);
                            },
                          );
                        }),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () {
                            navStack.removeLast();
                            print(navStack);
                            Navigator.pop(context);
                          },
                          color: isLoading
                              ? Theme.of(context).accentColor
                              : accent.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                          icon: Icon(
                            JamIcons.chevron_left,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IconButton(
                          onPressed: () {
                            var link = Provider.of<WallHavenProvider>(context,
                                    listen: false)
                                .walls[index]
                                .path;
                            Navigator.push(
                                context,
                                PageRouteBuilder(
                                    transitionDuration:
                                        Duration(milliseconds: 300),
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
                                      animation = Tween(begin: 0.0, end: 1.0)
                                          .animate(animation);
                                      return FadeTransition(
                                          opacity: animation,
                                          child: ClockOverlay(
                                            colorChanged: colorChanged,
                                            accent: accent,
                                            link: link,
                                            file: false,
                                          ));
                                    },
                                    fullscreenDialog: true,
                                    opaque: false));
                          },
                          color: isLoading
                              ? Theme.of(context).accentColor
                              : accent.computeLuminance() > 0.5
                                  ? Colors.black
                                  : Colors.white,
                          icon: Icon(
                            JamIcons.clock,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            )
          : provider == "Prism"
              ? Scaffold(
                  resizeToAvoidBottomPadding: false,
                  key: _scaffoldKey,
                  backgroundColor:
                      isLoading ? Theme.of(context).primaryColor : accent,
                  body: SlidingUpPanel(
                    onPanelOpened: () {
                      if (panelClosed) {
                        print('Screenshot Starting');
                        setState(() {
                          panelClosed = false;
                        });
                        screenshotController
                            .capture(
                          pixelRatio: 3,
                          delay: Duration(milliseconds: 10),
                        )
                            .then((File image) async {
                          setState(() {
                            _imageFile = image;
                            screenshotTaken = true;
                          });
                          print('Screenshot Taken');
                        }).catchError((onError) {
                          print(onError);
                        });
                      }
                    },
                    onPanelClosed: () {
                      setState(() {
                        panelClosed = true;
                      });
                    },
                    backdropEnabled: true,
                    backdropTapClosesPanel: true,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [],
                    collapsed: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          color: Color(0xFF2F2F2F)),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 20,
                        child: Center(
                            child: Icon(
                          JamIcons.chevron_up,
                          color: Colors.white,
                        )),
                      ),
                    ),
                    minHeight: MediaQuery.of(context).size.height / 20,
                    parallaxEnabled: true,
                    parallaxOffset: 0.54,
                    color: Color(0xFF2F2F2F),
                    maxHeight: MediaQuery.of(context).size.height * .46,
                    controller: panelController,
                    panel: Container(
                      height: MediaQuery.of(context).size.height * .46,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        color: Color(0xFF2F2F2F),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Center(
                              child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(
                              JamIcons.chevron_down,
                              color: Colors.white,
                            ),
                          )),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                colors == null ? 5 : colors.length,
                                (color) {
                                  return GestureDetector(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colors == null
                                              ? Color(0xFF000000)
                                              : colors[color],
                                          borderRadius:
                                              BorderRadius.circular(500),
                                        ),
                                        height:
                                            MediaQuery.of(context).size.width /
                                                8,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                8,
                                      ),
                                      onTap: () {
                                        navStack.removeLast();
                                        print(navStack);
                                        SystemChrome
                                            .setEnabledSystemUIOverlays([
                                          SystemUiOverlay.top,
                                          SystemUiOverlay.bottom
                                        ]);
                                        Future.delayed(Duration(seconds: 0))
                                            .then((value) =>
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  ColorRoute,
                                                  arguments: [
                                                    colors[color]
                                                        .toString()
                                                        .replaceAll(
                                                            "Color(0xff", "")
                                                        .replaceAll(")", ""),
                                                  ],
                                                ));
                                      });
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(35, 0, 35, 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 5, 0, 10),
                                        child: Text(
                                          Provider.of<PrismProvider>(context,
                                                  listen: false)
                                              .subPrismWalls[index]["id"]
                                              .toString()
                                              .toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            JamIcons.camera,
                                            size: 20,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "${Provider.of<PrismProvider>(context, listen: false).subPrismWalls[index]["by"].toString()}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            JamIcons.arrow_circle_right,
                                            size: 20,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "${Provider.of<PrismProvider>(context, listen: false).subPrismWalls[index]["desc"].toString()}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            JamIcons.save,
                                            size: 20,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "${Provider.of<PrismProvider>(context, listen: false).subPrismWalls[index]["size"].toString()}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 0),
                                        child: Row(
                                          children: [
                                            Text(
                                              Provider.of<PrismProvider>(
                                                      context,
                                                      listen: false)
                                                  .subPrismWalls[index]
                                                      ["category"]
                                                  .toString(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText2,
                                            ),
                                            SizedBox(width: 10),
                                            Icon(
                                              JamIcons.unordered_list,
                                              size: 20,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            "${Provider.of<PrismProvider>(context, listen: false).subPrismWalls[index]["resolution"].toString()}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            JamIcons.set_square,
                                            size: 20,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            provider.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                          SizedBox(width: 10),
                                          Icon(
                                            JamIcons.database,
                                            size: 20,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                DownloadButton(
                                    colorChanged: colorChanged,
                                    link: screenshotTaken
                                        ? _imageFile.path
                                        : Provider.of<PrismProvider>(context,
                                                listen: false)
                                            .subPrismWalls[index]
                                                ["wallpaper_url"]
                                            .toString()),
                                SetWallpaperButton(
                                    colorChanged: colorChanged,
                                    url: screenshotTaken
                                        ? _imageFile.path
                                        : Provider.of<PrismProvider>(context)
                                                .subPrismWalls[index]
                                            ["wallpaper_url"]),
                                FavouriteWallpaperButton(
                                  id: Provider.of<PrismProvider>(context,
                                          listen: false)
                                      .subPrismWalls[index]["id"]
                                      .toString(),
                                  provider: "Prism",
                                  prism: Provider.of<PrismProvider>(context,
                                          listen: false)
                                      .subPrismWalls[index],
                                  trash: false,
                                ),
                                ShareButton(
                                    id: Provider.of<PrismProvider>(context,
                                            listen: false)
                                        .subPrismWalls[index]["id"],
                                    provider: provider,
                                    url: Provider.of<PrismProvider>(context,
                                            listen: false)
                                        .subPrismWalls[index]["wallpaper_url"],
                                    thumbUrl: Provider.of<PrismProvider>(
                                                context,
                                                listen: false)
                                            .subPrismWalls[index]
                                        ["wallpaper_thumb"])
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    body: Stack(
                      children: <Widget>[
                        AnimatedBuilder(
                            animation: offsetAnimation,
                            builder: (buildContext, child) {
                              if (offsetAnimation.value < 0.0)
                                print('${offsetAnimation.value + 8.0}');
                              return GestureDetector(
                                child: CachedNetworkImage(
                                  imageUrl: Provider.of<PrismProvider>(context)
                                      .subPrismWalls[index]["wallpaper_url"],
                                  imageBuilder: (context, imageProvider) =>
                                      Screenshot(
                                    controller: screenshotController,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                          vertical:
                                              offsetAnimation.value * 1.25,
                                          horizontal:
                                              offsetAnimation.value / 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            offsetAnimation.value),
                                        image: DecorationImage(
                                          colorFilter: colorChanged
                                              ? ColorFilter.mode(
                                                  accent, BlendMode.hue)
                                              : null,
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  placeholder: (context, url) => Stack(
                                    children: <Widget>[
                                      SizedBox.expand(child: Text("")),
                                      Container(
                                        child: Center(
                                          child: Loader(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    child: Center(
                                      child: Icon(
                                        JamIcons.close_circle_f,
                                        color: isLoading
                                            ? Theme.of(context).accentColor
                                            : accent.computeLuminance() > 0.5
                                                ? Colors.black
                                                : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                onPanUpdate: (details) {
                                  if (details.delta.dy < -10) {
                                    panelController.open();
                                    HapticFeedback.vibrate();
                                  }
                                },
                                onLongPress: () {
                                  setState(() {
                                    colorChanged = false;
                                  });
                                  HapticFeedback.vibrate();
                                  shakeController.forward(from: 0.0);
                                },
                                onTap: () {
                                  HapticFeedback.vibrate();
                                  !isLoading ? updateAccent() : print("");
                                  shakeController.forward(from: 0.0);
                                },
                              );
                            }),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
                              onPressed: () {
                                navStack.removeLast();
                                print(navStack);
                                Navigator.pop(context);
                              },
                              color: isLoading
                                  ? Theme.of(context).accentColor
                                  : accent.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                              icon: Icon(
                                JamIcons.chevron_left,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IconButton(
                              onPressed: () {
                                var link = Provider.of<PrismProvider>(context,
                                        listen: false)
                                    .subPrismWalls[index]["wallpaper_url"];
                                Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                        transitionDuration:
                                            Duration(milliseconds: 300),
                                        pageBuilder: (context, animation,
                                            secondaryAnimation) {
                                          animation =
                                              Tween(begin: 0.0, end: 1.0)
                                                  .animate(animation);
                                          return FadeTransition(
                                              opacity: animation,
                                              child: ClockOverlay(
                                                colorChanged: colorChanged,
                                                accent: accent,
                                                link: link,
                                                file: false,
                                              ));
                                        },
                                        fullscreenDialog: true,
                                        opaque: false));
                              },
                              color: isLoading
                                  ? Theme.of(context).accentColor
                                  : accent.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                              icon: Icon(
                                JamIcons.clock,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : provider == "Pexels"
                  ? Scaffold(
                      resizeToAvoidBottomPadding: false,
                      key: _scaffoldKey,
                      backgroundColor:
                          isLoading ? Theme.of(context).primaryColor : accent,
                      body: SlidingUpPanel(
                        onPanelOpened: () {
                          if (panelClosed) {
                            print('Screenshot Starting');
                            setState(() {
                              panelClosed = false;
                            });
                            screenshotController
                                .capture(
                              pixelRatio: 3,
                              delay: Duration(milliseconds: 10),
                            )
                                .then((File image) async {
                              setState(() {
                                _imageFile = image;
                                screenshotTaken = true;
                              });
                              print('Screenshot Taken');
                            }).catchError((onError) {
                              print(onError);
                            });
                          }
                        },
                        onPanelClosed: () {
                          setState(() {
                            panelClosed = true;
                          });
                        },
                        backdropEnabled: true,
                        backdropTapClosesPanel: true,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [],
                        collapsed: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              color: Color(0xFF2F2F2F)),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height / 20,
                            child: Center(
                                child: Icon(
                              JamIcons.chevron_up,
                              color: Colors.white,
                            )),
                          ),
                        ),
                        minHeight: MediaQuery.of(context).size.height / 20,
                        parallaxEnabled: true,
                        parallaxOffset: 0.54,
                        color: Color(0xFF2F2F2F),
                        maxHeight: MediaQuery.of(context).size.height * .46,
                        controller: panelController,
                        panel: Container(
                          height: MediaQuery.of(context).size.height * .46,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            color: Color(0xFF2F2F2F),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Center(
                                  child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Icon(
                                  JamIcons.chevron_down,
                                  color: Colors.white,
                                ),
                              )),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    colors == null ? 5 : colors.length,
                                    (color) {
                                      return GestureDetector(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors == null
                                                  ? Color(0xFF000000)
                                                  : colors[color],
                                              borderRadius:
                                                  BorderRadius.circular(500),
                                            ),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                8,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                8,
                                          ),
                                          onTap: () {
                                            navStack.removeLast();
                                            print(navStack);
                                            SystemChrome
                                                .setEnabledSystemUIOverlays([
                                              SystemUiOverlay.top,
                                              SystemUiOverlay.bottom
                                            ]);
                                            Future.delayed(Duration(seconds: 0))
                                                .then((value) => Navigator
                                                        .pushReplacementNamed(
                                                      context,
                                                      ColorRoute,
                                                      arguments: [
                                                        colors[color]
                                                            .toString()
                                                            .replaceAll(
                                                                "Color(0xff",
                                                                "")
                                                            .replaceAll(
                                                                ")", ""),
                                                      ],
                                                    ));
                                          });
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(35, 0, 35, 15),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 5, 0, 10),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              .8,
                                          child: Text(
                                            Provider.of<PexelsProvider>(context, listen: false).wallsP[index].url.toString().replaceAll("https://www.pexels.com/photo/", "").replaceAll("-", " ").replaceAll("/", "").length > 8
                                                ? Provider.of<PexelsProvider>(context, listen: false)
                                                        .wallsP[index]
                                                        .url
                                                        .toString()
                                                        .replaceAll(
                                                            "https://www.pexels.com/photo/", "")
                                                        .replaceAll("-", " ")
                                                        .replaceAll("/", "")[0]
                                                        .toUpperCase() +
                                                    Provider.of<PexelsProvider>(context, listen: false)
                                                        .wallsP[index]
                                                        .url
                                                        .toString()
                                                        .replaceAll(
                                                            "https://www.pexels.com/photo/", "")
                                                        .replaceAll("-", " ")
                                                        .replaceAll("/", "")
                                                        .substring(
                                                            1,
                                                            Provider.of<PexelsProvider>(context, listen: false).wallsP[index].url.toString().replaceAll("https://www.pexels.com/photo/", "").replaceAll("-", " ").replaceAll("/", "").length -
                                                                7)
                                                : Provider.of<PexelsProvider>(context, listen: false)
                                                        .wallsP[index]
                                                        .url
                                                        .toString()
                                                        .replaceAll(
                                                            "https://www.pexels.com/photo/", "")
                                                        .replaceAll("-", " ")
                                                        .replaceAll("/", "")[0]
                                                        .toUpperCase() +
                                                    Provider.of<PexelsProvider>(
                                                            context,
                                                            listen: false)
                                                        .wallsP[index]
                                                        .url
                                                        .toString()
                                                        .replaceAll("https://www.pexels.com/photo/", "")
                                                        .replaceAll("-", " ")
                                                        .replaceAll("/", "")
                                                        .substring(1),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Row(
                                                children: [
                                                  Icon(
                                                    JamIcons.camera,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            .4,
                                                    child: Text(
                                                      Provider.of<PexelsProvider>(
                                                              context,
                                                              listen: false)
                                                          .wallsP[index]
                                                          .photographer
                                                          .toString(),
                                                      textAlign: TextAlign.left,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyText2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Icon(
                                                    JamIcons.set_square,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${Provider.of<PexelsProvider>(context, listen: false).wallsP[index].width.toString()}x${Provider.of<PexelsProvider>(context, listen: false).wallsP[index].height.toString()}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Row(
                                                children: [
                                                  Text(
                                                    Provider.of<PexelsProvider>(
                                                            context,
                                                            listen: false)
                                                        .wallsP[index]
                                                        .id
                                                        .toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(
                                                    JamIcons.info,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Text(
                                                    provider.toString(),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(
                                                    JamIcons.database,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    DownloadButton(
                                        colorChanged: colorChanged,
                                        link: screenshotTaken
                                            ? _imageFile.path
                                            : Provider.of<PexelsProvider>(
                                                    context,
                                                    listen: false)
                                                .wallsP[index]
                                                .src["original"]
                                                .toString()),
                                    SetWallpaperButton(
                                        colorChanged: colorChanged,
                                        url: screenshotTaken
                                            ? _imageFile.path
                                            : Provider.of<PexelsProvider>(
                                                    context)
                                                .wallsP[index]
                                                .src["original"]),
                                    FavouriteWallpaperButton(
                                      id: Provider.of<PexelsProvider>(context,
                                              listen: false)
                                          .wallsP[index]
                                          .id
                                          .toString(),
                                      provider: "Pexels",
                                      pexels: Provider.of<PexelsProvider>(
                                              context,
                                              listen: false)
                                          .wallsP[index],
                                      trash: false,
                                    ),
                                    ShareButton(
                                        id: Provider.of<PexelsProvider>(context,
                                                listen: false)
                                            .wallsP[index]
                                            .id,
                                        provider: provider,
                                        url: Provider.of<PexelsProvider>(
                                                context,
                                                listen: false)
                                            .wallsP[index]
                                            .src["original"],
                                        thumbUrl: Provider.of<PexelsProvider>(
                                                context,
                                                listen: false)
                                            .wallsP[index]
                                            .src["medium"])
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        body: Stack(
                          children: <Widget>[
                            AnimatedBuilder(
                                animation: offsetAnimation,
                                builder: (buildContext, child) {
                                  if (offsetAnimation.value < 0.0)
                                    print('${offsetAnimation.value + 8.0}');
                                  return GestureDetector(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          Provider.of<PexelsProvider>(context)
                                              .wallsP[index]
                                              .src["portrait"],
                                      imageBuilder: (context, imageProvider) =>
                                          Screenshot(
                                        controller: screenshotController,
                                        child: Container(
                                          margin: EdgeInsets.symmetric(
                                              vertical:
                                                  offsetAnimation.value * 1.25,
                                              horizontal:
                                                  offsetAnimation.value / 2),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                offsetAnimation.value),
                                            image: DecorationImage(
                                              colorFilter: colorChanged
                                                  ? ColorFilter.mode(
                                                      accent, BlendMode.hue)
                                                  : null,
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      placeholder: (context, url) => Stack(
                                        children: <Widget>[
                                          SizedBox.expand(child: Text("")),
                                          Container(
                                            child: Center(
                                              child: Loader(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        child: Center(
                                          child: Icon(
                                            JamIcons.close_circle_f,
                                            color: isLoading
                                                ? Theme.of(context).accentColor
                                                : accent.computeLuminance() >
                                                        0.5
                                                    ? Colors.black
                                                    : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    onPanUpdate: (details) {
                                      if (details.delta.dy < -10) {
                                        HapticFeedback.vibrate();
                                        panelController.open();
                                      }
                                    },
                                    onLongPress: () {
                                      setState(() {
                                        colorChanged = false;
                                      });
                                      HapticFeedback.vibrate();
                                      shakeController.forward(from: 0.0);
                                    },
                                    onTap: () {
                                      HapticFeedback.vibrate();
                                      !isLoading ? updateAccent() : print("");
                                      shakeController.forward(from: 0.0);
                                    },
                                  );
                                }),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  onPressed: () {
                                    navStack.removeLast();
                                    print(navStack);
                                    Navigator.pop(context);
                                  },
                                  color: isLoading
                                      ? Theme.of(context).accentColor
                                      : accent.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                  icon: Icon(
                                    JamIcons.chevron_left,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IconButton(
                                  onPressed: () {
                                    var link = Provider.of<PexelsProvider>(
                                            context,
                                            listen: false)
                                        .wallsP[index]
                                        .src["portrait"];
                                    Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                            transitionDuration:
                                                Duration(milliseconds: 300),
                                            pageBuilder: (context, animation,
                                                secondaryAnimation) {
                                              animation =
                                                  Tween(begin: 0.0, end: 1.0)
                                                      .animate(animation);
                                              return FadeTransition(
                                                  opacity: animation,
                                                  child: ClockOverlay(
                                                    colorChanged: colorChanged,
                                                    accent: accent,
                                                    link: link,
                                                    file: false,
                                                  ));
                                            },
                                            fullscreenDialog: true,
                                            opaque: false));
                                  },
                                  color: isLoading
                                      ? Theme.of(context).accentColor
                                      : accent.computeLuminance() > 0.5
                                          ? Colors.black
                                          : Colors.white,
                                  icon: Icon(
                                    JamIcons.clock,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : provider.length > 6 && provider.substring(0, 6) == "Colors"
                      ? Scaffold(
                          resizeToAvoidBottomPadding: false,
                          key: _scaffoldKey,
                          backgroundColor: isLoading
                              ? Theme.of(context).primaryColor
                              : accent,
                          body: SlidingUpPanel(
                            onPanelOpened: () {
                              if (panelClosed) {
                                print('Screenshot Starting');
                                setState(() {
                                  panelClosed = false;
                                });
                                screenshotController
                                    .capture(
                                  pixelRatio: 3,
                                  delay: Duration(milliseconds: 10),
                                )
                                    .then((File image) async {
                                  setState(() {
                                    _imageFile = image;
                                    screenshotTaken = true;
                                  });
                                  print('Screenshot Taken');
                                }).catchError((onError) {
                                  print(onError);
                                });
                              }
                            },
                            onPanelClosed: () {
                              setState(() {
                                panelClosed = true;
                              });
                            },
                            backdropEnabled: true,
                            backdropTapClosesPanel: true,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            boxShadow: [],
                            collapsed: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  color: Color(0xFF2F2F2F)),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height / 20,
                                child: Center(
                                    child: Icon(
                                  JamIcons.chevron_up,
                                  color: Colors.white,
                                )),
                              ),
                            ),
                            minHeight: MediaQuery.of(context).size.height / 20,
                            parallaxEnabled: true,
                            parallaxOffset: 0.54,
                            color: Color(0xFF2F2F2F),
                            maxHeight: MediaQuery.of(context).size.height * .46,
                            controller: panelController,
                            panel: Container(
                              height: MediaQuery.of(context).size.height * .46,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                color: Color(0xFF2F2F2F),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Center(
                                      child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Icon(
                                      JamIcons.chevron_down,
                                      color: Colors.white,
                                    ),
                                  )),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(
                                        colors == null ? 5 : colors.length,
                                        (color) {
                                          return GestureDetector(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: colors == null
                                                      ? Color(0xFF000000)
                                                      : colors[color],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          500),
                                                ),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    8,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    8,
                                              ),
                                              onTap: () {
                                                navStack.removeLast();
                                                print(navStack);
                                                SystemChrome
                                                    .setEnabledSystemUIOverlays([
                                                  SystemUiOverlay.top,
                                                  SystemUiOverlay.bottom
                                                ]);
                                                Future.delayed(
                                                        Duration(seconds: 0))
                                                    .then((value) => Navigator
                                                            .pushReplacementNamed(
                                                          context,
                                                          ColorRoute,
                                                          arguments: [
                                                            colors[color]
                                                                .toString()
                                                                .replaceAll(
                                                                    "Color(0xff",
                                                                    "")
                                                                .replaceAll(
                                                                    ")", ""),
                                                          ],
                                                        ));
                                              });
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          35, 0, 35, 15),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 5, 0, 10),
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  .8,
                                              child: Text(
                                                Provider.of<PexelsProvider>(context, listen: false).wallsC[index].url.toString().replaceAll("https://www.pexels.com/photo/", "").replaceAll("-", " ").replaceAll("/", "").length > 8
                                                    ? Provider.of<PexelsProvider>(context, listen: false)
                                                            .wallsC[index]
                                                            .url
                                                            .toString()
                                                            .replaceAll(
                                                                "https://www.pexels.com/photo/", "")
                                                            .replaceAll(
                                                                "-", " ")
                                                            .replaceAll(
                                                                "/", "")[0]
                                                            .toUpperCase() +
                                                        Provider.of<PexelsProvider>(context, listen: false)
                                                            .wallsC[index]
                                                            .url
                                                            .toString()
                                                            .replaceAll(
                                                                "https://www.pexels.com/photo/", "")
                                                            .replaceAll(
                                                                "-", " ")
                                                            .replaceAll("/", "")
                                                            .substring(
                                                                1,
                                                                Provider.of<PexelsProvider>(context, listen: false).wallsC[index].url.toString().replaceAll("https://www.pexels.com/photo/", "").replaceAll("-", " ").replaceAll("/", "").length -
                                                                    7)
                                                    : Provider.of<PexelsProvider>(context, listen: false)
                                                            .wallsC[index]
                                                            .url
                                                            .toString()
                                                            .replaceAll(
                                                                "https://www.pexels.com/photo/", "")
                                                            .replaceAll("-", " ")
                                                            .replaceAll("/", "")[0]
                                                            .toUpperCase() +
                                                        Provider.of<PexelsProvider>(context, listen: false).wallsC[index].url.toString().replaceAll("https://www.pexels.com/photo/", "").replaceAll("-", " ").replaceAll("/", "").substring(1),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        JamIcons.camera,
                                                        size: 20,
                                                        color: Colors.white70,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Container(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            .4,
                                                        child: Text(
                                                          Provider.of<PexelsProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .wallsC[index]
                                                              .photographer
                                                              .toString(),
                                                          textAlign:
                                                              TextAlign.left,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyText2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        JamIcons.set_square,
                                                        size: 20,
                                                        color: Colors.white70,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text(
                                                        "${Provider.of<PexelsProvider>(context, listen: false).wallsC[index].width.toString()}x${Provider.of<PexelsProvider>(context, listen: false).wallsC[index].height.toString()}",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyText2,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: <Widget>[
                                                  Row(
                                                    children: [
                                                      Text(
                                                        Provider.of<PexelsProvider>(
                                                                context,
                                                                listen: false)
                                                            .wallsC[index]
                                                            .id
                                                            .toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyText2,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Icon(
                                                        JamIcons.info,
                                                        size: 20,
                                                        color: Colors.white70,
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 5),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        "Pexels",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyText2,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Icon(
                                                        JamIcons.database,
                                                        size: 20,
                                                        color: Colors.white70,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        DownloadButton(
                                          colorChanged: colorChanged,
                                          link: screenshotTaken
                                              ? _imageFile.path
                                              : Provider.of<PexelsProvider>(
                                                      context,
                                                      listen: false)
                                                  .wallsC[index]
                                                  .src["original"]
                                                  .toString(),
                                        ),
                                        SetWallpaperButton(
                                            colorChanged: colorChanged,
                                            url: screenshotTaken
                                                ? _imageFile.path
                                                : Provider.of<PexelsProvider>(
                                                        context)
                                                    .wallsC[index]
                                                    .src["original"]),
                                        FavouriteWallpaperButton(
                                          id: Provider.of<PexelsProvider>(
                                                  context,
                                                  listen: false)
                                              .wallsC[index]
                                              .id
                                              .toString(),
                                          provider: "Pexels",
                                          pexels: Provider.of<PexelsProvider>(
                                                  context,
                                                  listen: false)
                                              .wallsC[index],
                                          trash: false,
                                        ),
                                        ShareButton(
                                            id: Provider.of<PexelsProvider>(
                                                    context,
                                                    listen: false)
                                                .wallsC[index]
                                                .id,
                                            provider: "Pexels",
                                            url: Provider.of<PexelsProvider>(
                                                    context,
                                                    listen: false)
                                                .wallsC[index]
                                                .src["original"],
                                            thumbUrl:
                                                Provider.of<PexelsProvider>(
                                                        context,
                                                        listen: false)
                                                    .wallsC[index]
                                                    .src["medium"])
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            body: Stack(
                              children: <Widget>[
                                Provider.of<PexelsProvider>(context).wallsC ==
                                        null
                                    ? Container()
                                    : AnimatedBuilder(
                                        animation: offsetAnimation,
                                        builder: (buildContext, child) {
                                          if (offsetAnimation.value < 0.0)
                                            print(
                                                '${offsetAnimation.value + 8.0}');
                                          return GestureDetector(
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  Provider.of<PexelsProvider>(
                                                          context,
                                                          listen: false)
                                                      .wallsC[index]
                                                      .src["portrait"],
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Screenshot(
                                                controller:
                                                    screenshotController,
                                                child: Container(
                                                  margin: EdgeInsets.symmetric(
                                                      vertical: offsetAnimation
                                                              .value *
                                                          1.25,
                                                      horizontal:
                                                          offsetAnimation
                                                                  .value /
                                                              2),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            offsetAnimation
                                                                .value),
                                                    image: DecorationImage(
                                                      colorFilter: colorChanged
                                                          ? ColorFilter.mode(
                                                              accent,
                                                              BlendMode.hue)
                                                          : null,
                                                      image: imageProvider,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              placeholder: (context, url) =>
                                                  Stack(
                                                children: <Widget>[
                                                  SizedBox.expand(
                                                      child: Text("")),
                                                  Container(
                                                    child: Center(
                                                      child: Loader(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                child: Center(
                                                  child: Icon(
                                                    JamIcons.close_circle_f,
                                                    color: isLoading
                                                        ? Theme.of(context)
                                                            .accentColor
                                                        : accent.computeLuminance() >
                                                                0.5
                                                            ? Colors.black
                                                            : Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            onPanUpdate: (details) {
                                              if (details.delta.dy < -10) {
                                                HapticFeedback.vibrate();
                                                panelController.open();
                                              }
                                            },
                                            onLongPress: () {
                                              setState(() {
                                                colorChanged = false;
                                              });
                                              HapticFeedback.vibrate();
                                              shakeController.forward(
                                                  from: 0.0);
                                            },
                                            onTap: () {
                                              HapticFeedback.vibrate();
                                              !isLoading
                                                  ? updateAccent()
                                                  : print("");
                                              shakeController.forward(
                                                  from: 0.0);
                                            },
                                          );
                                        }),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      onPressed: () {
                                        navStack.removeLast();
                                        print(navStack);
                                        Navigator.pop(context);
                                      },
                                      color: isLoading
                                          ? Theme.of(context).accentColor
                                          : accent.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                      icon: Icon(
                                        JamIcons.chevron_left,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      onPressed: () {
                                        var link = Provider.of<PexelsProvider>(
                                                context,
                                                listen: false)
                                            .wallsC[index]
                                            .src["portrait"];
                                        Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                                transitionDuration:
                                                    Duration(milliseconds: 300),
                                                pageBuilder: (context,
                                                    animation,
                                                    secondaryAnimation) {
                                                  animation = Tween(
                                                          begin: 0.0, end: 1.0)
                                                      .animate(animation);
                                                  return FadeTransition(
                                                      opacity: animation,
                                                      child: ClockOverlay(
                                                        colorChanged:
                                                            colorChanged,
                                                        accent: accent,
                                                        link: link,
                                                        file: false,
                                                      ));
                                                },
                                                fullscreenDialog: true,
                                                opaque: false));
                                      },
                                      color: isLoading
                                          ? Theme.of(context).accentColor
                                          : accent.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                      icon: Icon(
                                        JamIcons.clock,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        )
                      : Scaffold(
                          resizeToAvoidBottomPadding: false,
                          key: _scaffoldKey,
                          backgroundColor: isLoading
                              ? Theme.of(context).primaryColor
                              : accent,
                          body: SlidingUpPanel(
                            onPanelOpened: () {
                              if (panelClosed) {
                                print('Screenshot Starting');
                                setState(() {
                                  panelClosed = false;
                                });
                                screenshotController
                                    .capture(
                                  pixelRatio: 3,
                                  delay: Duration(milliseconds: 10),
                                )
                                    .then((File image) async {
                                  setState(() {
                                    _imageFile = image;
                                    screenshotTaken = true;
                                  });
                                  print('Screenshot Taken');
                                }).catchError((onError) {
                                  print(onError);
                                });
                              }
                            },
                            onPanelClosed: () {
                              setState(() {
                                panelClosed = true;
                              });
                            },
                            backdropEnabled: true,
                            backdropTapClosesPanel: true,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            boxShadow: [],
                            collapsed: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                  color: Color(0xFF2F2F2F)),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height / 20,
                                child: Center(
                                    child: Icon(
                                  JamIcons.chevron_up,
                                  color: Colors.white,
                                )),
                              ),
                            ),
                            minHeight: MediaQuery.of(context).size.height / 20,
                            parallaxEnabled: true,
                            parallaxOffset: 0.54,
                            color: Color(0xFF2F2F2F),
                            maxHeight: MediaQuery.of(context).size.height * .46,
                            controller: panelController,
                            panel: Container(
                              height: MediaQuery.of(context).size.height * .46,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                color: Color(0xFF2F2F2F),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Center(
                                      child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Icon(
                                      JamIcons.chevron_down,
                                      color: Colors.white,
                                    ),
                                  )),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: List.generate(
                                        colors == null ? 5 : colors.length,
                                        (color) {
                                          return GestureDetector(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: colors == null
                                                      ? Color(0xFF000000)
                                                      : colors[color],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          500),
                                                ),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    8,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    8,
                                              ),
                                              onTap: () {
                                                navStack.removeLast();
                                                print(navStack);
                                                SystemChrome
                                                    .setEnabledSystemUIOverlays([
                                                  SystemUiOverlay.top,
                                                  SystemUiOverlay.bottom
                                                ]);
                                                Future.delayed(
                                                        Duration(seconds: 0))
                                                    .then((value) => Navigator
                                                            .pushReplacementNamed(
                                                          context,
                                                          ColorRoute,
                                                          arguments: [
                                                            colors[color]
                                                                .toString()
                                                                .replaceAll(
                                                                    "Color(0xff",
                                                                    "")
                                                                .replaceAll(
                                                                    ")", ""),
                                                          ],
                                                        ));
                                              });
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          35, 0, 35, 15),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: <Widget>[
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 5, 0, 10),
                                                child: Text(
                                                  Provider.of<WallHavenProvider>(
                                                          context,
                                                          listen: false)
                                                      .wallsS[index]
                                                      .id
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    JamIcons.eye,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${Provider.of<WallHavenProvider>(context, listen: false).wallsS[index].views.toString()}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Icon(
                                                    JamIcons.heart_f,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${Provider.of<WallHavenProvider>(context, listen: false).wallsS[index].favourites.toString()}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Icon(
                                                    JamIcons.save,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "${double.parse(((double.parse(Provider.of<WallHavenProvider>(context, listen: false).wallsS[index].file_size.toString()) / 1000000).toString())).toStringAsFixed(2)} MB",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 0, 0, 0),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      Provider.of<WallHavenProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .wallsS[index]
                                                              .category
                                                              .toString()[0]
                                                              .toUpperCase() +
                                                          Provider.of<WallHavenProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .wallsS[index]
                                                              .category
                                                              .toString()
                                                              .substring(1),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyText2,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Icon(
                                                      JamIcons.unordered_list,
                                                      size: 20,
                                                      color: Colors.white70,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Text(
                                                    "${Provider.of<WallHavenProvider>(context, listen: false).wallsS[index].resolution.toString()}",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(
                                                    JamIcons.set_square,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Text(
                                                    provider
                                                            .toString()[0]
                                                            .toUpperCase() +
                                                        provider
                                                            .toString()
                                                            .substring(1),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyText2,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Icon(
                                                    JamIcons.search,
                                                    size: 20,
                                                    color: Colors.white70,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: <Widget>[
                                        DownloadButton(
                                          colorChanged: colorChanged,
                                          link: screenshotTaken
                                              ? _imageFile.path
                                              : Provider.of<WallHavenProvider>(
                                                      context,
                                                      listen: false)
                                                  .wallsS[index]
                                                  .path
                                                  .toString(),
                                        ),
                                        SetWallpaperButton(
                                            colorChanged: colorChanged,
                                            url: screenshotTaken
                                                ? _imageFile.path
                                                : Provider.of<
                                                            WallHavenProvider>(
                                                        context)
                                                    .wallsS[index]
                                                    .path),
                                        FavouriteWallpaperButton(
                                          id: Provider.of<WallHavenProvider>(
                                                  context,
                                                  listen: false)
                                              .wallsS[index]
                                              .id
                                              .toString(),
                                          provider: "WallHaven",
                                          wallhaven:
                                              Provider.of<WallHavenProvider>(
                                                      context,
                                                      listen: false)
                                                  .wallsS[index],
                                          trash: false,
                                        ),
                                        ShareButton(
                                            id: Provider.of<WallHavenProvider>(
                                                    context,
                                                    listen: false)
                                                .wallsS[index]
                                                .id,
                                            provider: "WallHaven",
                                            url: Provider.of<WallHavenProvider>(
                                                    context,
                                                    listen: false)
                                                .wallsS[index]
                                                .path,
                                            thumbUrl:
                                                Provider.of<WallHavenProvider>(
                                                        context,
                                                        listen: false)
                                                    .wallsS[index]
                                                    .thumbs["original"])
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            body: Stack(
                              children: <Widget>[
                                AnimatedBuilder(
                                    animation: offsetAnimation,
                                    builder: (buildContext, child) {
                                      if (offsetAnimation.value < 0.0)
                                        print('${offsetAnimation.value + 8.0}');
                                      return GestureDetector(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              Provider.of<WallHavenProvider>(
                                                      context)
                                                  .wallsS[index]
                                                  .path,
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Screenshot(
                                            controller: screenshotController,
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                  vertical:
                                                      offsetAnimation.value *
                                                          1.25,
                                                  horizontal:
                                                      offsetAnimation.value /
                                                          2),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        offsetAnimation.value),
                                                image: DecorationImage(
                                                  colorFilter: colorChanged
                                                      ? ColorFilter.mode(
                                                          accent, BlendMode.hue)
                                                      : null,
                                                  image: imageProvider,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          placeholder: (context, url) => Stack(
                                            children: <Widget>[
                                              SizedBox.expand(child: Text("")),
                                              Container(
                                                child: Center(
                                                  child: Loader(),
                                                ),
                                              ),
                                            ],
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            child: Center(
                                              child: Icon(
                                                JamIcons.close_circle_f,
                                                color: isLoading
                                                    ? Theme.of(context)
                                                        .accentColor
                                                    : accent.computeLuminance() >
                                                            0.5
                                                        ? Colors.black
                                                        : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        onPanUpdate: (details) {
                                          if (details.delta.dy < -10) {
                                            HapticFeedback.vibrate();
                                            panelController.open();
                                          }
                                        },
                                        onLongPress: () {
                                          setState(() {
                                            colorChanged = false;
                                          });
                                          HapticFeedback.vibrate();
                                          shakeController.forward(from: 0.0);
                                        },
                                        onTap: () {
                                          HapticFeedback.vibrate();
                                          !isLoading
                                              ? updateAccent()
                                              : print("");
                                          shakeController.forward(from: 0.0);
                                        },
                                      );
                                    }),
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      onPressed: () {
                                        navStack.removeLast();
                                        print(navStack);
                                        Navigator.pop(context);
                                      },
                                      color: isLoading
                                          ? Theme.of(context).accentColor
                                          : accent.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                      icon: Icon(
                                        JamIcons.chevron_left,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: IconButton(
                                      onPressed: () {
                                        var link =
                                            Provider.of<WallHavenProvider>(
                                                    context,
                                                    listen: false)
                                                .wallsS[index]
                                                .path;
                                        Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                                transitionDuration:
                                                    Duration(milliseconds: 300),
                                                pageBuilder: (context,
                                                    animation,
                                                    secondaryAnimation) {
                                                  animation = Tween(
                                                          begin: 0.0, end: 1.0)
                                                      .animate(animation);
                                                  return FadeTransition(
                                                      opacity: animation,
                                                      child: ClockOverlay(
                                                        colorChanged:
                                                            colorChanged,
                                                        accent: accent,
                                                        link: link,
                                                        file: false,
                                                      ));
                                                },
                                                fullscreenDialog: true,
                                                opaque: false));
                                      },
                                      color: isLoading
                                          ? Theme.of(context).accentColor
                                          : accent.computeLuminance() > 0.5
                                              ? Colors.black
                                              : Colors.white,
                                      icon: Icon(
                                        JamIcons.clock,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
    );
    // } catch (e) {
    //   print(e.toString());
    //   String route = currentRoute;
    // currentRoute = previousRoute;
    // previousRoute = route;
    // print(currentRoute);
    // Navigator.pop(context);
    //   return Container();
    // }
  }
}
