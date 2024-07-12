//
//  ViewController.m
//  Demo-UIImagePickerControllerError
//
//  Created by shadowlight on 2024/7/12.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h> // 用于UTType常量
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *resultLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Init TableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    
    // Init UILabel
    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 40 - 100, self.view.bounds.size.width, 40)];
    self.resultLabel.textColor = [UIColor blackColor];
    self.resultLabel.font = [UIFont systemFontOfSize:12];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    self.resultLabel.numberOfLines = 0;
    self.resultLabel.text = @"未选择";
    [self.view addSubview:self.resultLabel];
}

// MARK: UIImagePickerController Delegate

///  选择照片之后
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    __weak typeof(self)weakSelf = self;
    [picker dismissViewControllerAnimated:true completion:^{
        __strong typeof(self)strongSelf = weakSelf;
        if (strongSelf) {
            NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
            if ([type isEqualToString:(NSString *)kUTTypeMovie]) {
                NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
                if (videoUrl) {
                    NSLog(@"url = %@", videoUrl);
                    strongSelf.resultLabel.text = [NSString stringWithFormat:@"视频：%@", videoUrl];
                }else{
                    // TODO: error
                    NSLog(@"NSURL videoUrl 为空");
                    strongSelf.resultLabel.text = [NSString stringWithFormat:@"视频：NSURL videoUrl 为空"];
                }
            }
        }else{
            NSLog(@"LSJImagePickerHelper:被销毁强制销毁，不进行后续逻辑");
        }
    }];
}

/**
 相册代理取消操作
 低版本设备，不实现该方法，无法关闭相册
 @param picker 相册对象
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.resultLabel.text = @"未选择";
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = NO;
    imagePickerController.mediaTypes = @[(NSString *)kUTTypeMovie];
    
    // Fix: 不配置这个，系统默认会进行重新编码，存在特殊视频选择视频后，无法获取到 url，失败案例Demo：需要导入 #import <AVFoundation/AVFoundation.h>
//    imagePickerController.videoExportPreset = AVAssetExportPresetPassthrough;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"选择视频";
    }
    
    return cell;
}




@end
