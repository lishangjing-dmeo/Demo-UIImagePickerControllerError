Tag: 相册获取视频为空、iOS 11+、视频单元错误


## Error Example

测试视频原本是一个 7 分钟的视频，在最后的 5 秒存在错误单元，故将错误内容剪辑出作为开发测试

开始一直没有定位问题，偶然在用播放器播放的时候，发现一个片段是**黑**的

### UIPickerImageController 工作流程

打开相册 -> 选择视频 -> 解码 —> copy 到 tmp 目录 -> 返回 temp 目录的对应视频路径

问题剧透：在解码环节错误，导致后续并没有 copy 到 temp 目录


### 测试流程：
- 导入 Demo 中的测试视频到相册中
- 通过 Demo 项目调用 UIImagePickerController 选中视频
- 获取视频路径：为空


### Mac OS 测试情况

这个问题在 Mac OS 通过 QuickTime Player 进行低分辨率导出的时候，发现它也失败了

![WX20240712-103641](assets/WX20240712-103641.png)

该问题与音频无关，故我将音频文件移除




### “异常”视频信息

排查一：通过 FFmpeg 查看信息的数据：

`ffmpeg -i error.mp4`

```
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'error.mp4':
  Metadata:
    major_brand     : mp42
    minor_version   : 1
    compatible_brands: isommp41mp42
    creation_time   : 2024-07-12T02:05:48.000000Z
  Duration: 00:07:51.70, start: 0.000000, bitrate: 907 kb/s
  Stream #0:0[0x1](und): Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt709, progressive), 544x960, 904 kb/s, 30 fps, 30 tbr, 90k tbn (default)
      Metadata:
        creation_time   : 2024-07-12T02:05:48.000000Z
        handler_name    : Core Media Video
        vendor_id       : [0][0][0][0]
```


排查二：通过 ffmpeg 进行 copy 的时候，可以看到，这个视频是存在某个单元丢失的

`ffmpeg -i error.mp4 -c copy output.mp4`

```
[h264 @ 0x7fd1f1904680] Invalid NAL unit size (922763361 > 49775).
[h264 @ 0x7fd1f1904680] missing picture in access unit with size 49779
[h264 @ 0x7fd1f1904680] Invalid NAL unit size (922763361 > 49775).
[h264 @ 0x7fd1f1904680] Error splitting the input into NAL units.
[h264 @ 0x7fd1f1904680] Invalid NAL unit size (-627508124 > 4745).
...
[h264 @ 0x7fd1f1904680] co located POCs unavailable
```


虽然能确定是视频的问题，但是我们也不能保证从互联网上下载的所有视频，它的单元都是正常的，

目前来看，这种单元丢失的视频，在使用 ffmpeg 进行视频处理的时候，会出现错误日志，但是不会停止任务

但是将这个视频传递给三方的视频处理 SDK 时，可能会异常

**所以要根据自己的需求来决定是否要修复这个“问题”**

---

**Invalid NAL unit size (922763361 > 49775)**

解释：NAL（Network Abstraction Layer）单元是 H.264 编码视频流中的基本单元。这个错误提示表明，FFmpeg 试图处理的 NAL 单元大小不合法（通常是因为文件损坏或数据受损）。

**missing picture in access unit with size 49779**

解释：这个错误提示表明在当前访问单元（Access Unit）中缺少完整的图像数据，可能是数据丢失或损坏导致的。

**Error splitting the input into NAL units**

解释：FFmpeg 在尝试将输入数据划分为 NAL 单元时发生错误，这可能是由于文件损坏或格式不正确。

**co located POCs unavailable**

解释：POC（Picture Order Count）是 H.264 视频编解码中的一个概念，用于确定帧的显示顺序。这个错误提示表明某些 POC 数据不可用，可能是因为相关的 NAL 单元丢失或损坏。


--- 

## “解决（跳过）“ 这个问题的方式：

让苹果在选择相册视频后，不进行解码，直接 copy 至 tmp 目录

```
imagePickerController.videoExportPreset = AVAssetExportPresetPassthrough;
```