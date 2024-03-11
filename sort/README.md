# Preprocessing
以TGM测试序列，阿里云服务器为例：
1. （可选）制作EncodingTimePerSegmenTGM.csv文件。
2. （可选）调整generate_split_file_list_final.py文件。
    1. 第68行调整需要输出的txt文件。
    2. 第71行调整需要使用的csv文件。
    3. 第26，29，32行调整cfg文件夹位置。
    4. 第13行跳整folder位置。
3. （可选）运行 python3 generate_split_file_list_final.py
4. 更新/App中的程序，用最新编译出来的版本（编译过程看ECM编译的文档），编译出来的结果存放在ECM/bin中。
5. 调整execute.sh文件（需要调整的都是缺省路径，可以不调整，放在命令行运行时作为参数）。 
    1. 第19行输出文件路径（这是缺省路径，也可以不调整，放在命令行运行时作为参数）
    2. 第29行输入文件路径（这是缺省路径，也可以不调整，放在命令行运行时作为参数）
6. 运行 bash ./execute.sh sort_list_TGM.txt
