```note
deep first search
本质上是无限调用下去的树 因为递归和标记等
让其终止 或者树的分叉变少
dfs的时间复杂度是比较高的 O(N**X) N是阶段数 X是平均决策数
但空间复杂度就很低了
dfs有很多技巧比如减枝
未减去枝叶的多叉树如下
def dfs(pos.i):
    if ....:
        return    
    map[][]=1
    dfs(pos.1)
    dfs(pos.2)
    dfs(pos.3)
    map[][]=0
    ....
或者 
def dfs(pos.i):
    if ....:
        return    
    for i in range():
        if check(pos.i):
	    map[][]=1
            dfs(pos.1)
            map[][]=0
第二种形式往往是改了个循环就死一堆人    
最简单的dfs应用应该是排列数
def dfs(lis,cur):
    if cur+1==len(lis):
        print lis
    for i in range(cur,len(lis)):
        swap(cur,i)
        dfs(lis,cur+1)
        swap(cur,i) //回溯
===========================================================================
最简单的dfs
a[N] sum=0 求a[N]中各个数之和最大的情况 
def dfs(step,value):
    if step==n+1:
        sum=max(sum,value)#更新最后所有情况的sum和value
	return sum
    dfs(step+1,value)
    dfs(step+1,value+a[step]) #只有两种状态要么加要么不加
所以宏观来看 就是一颗具有n个阶段的二叉树

————————————————————————————————————
种子填充
第一种写法：
int m,n;  
char map[N][N];  
int ans;  
int visited[N][N];  
  
void dfs(int i,int j)  
{  
    if(i < 0 || i >= m || j < 0 || j >= n || visited[i][j] || map[i][j] == '*')
//终止条件：①走到边界了②已经走过了③不是符号@   
       return ;  
    visited[i][j] = 1;  
    dfs(i+1,j);
//在每一个点处都有八个方向可以走  其中八个方向可以通过一个二重循环来代替（见《算法入门经典》P163）   
    dfs(i-1,j);  
    dfs(i,j-1);  
    dfs(i,j+1);  
    dfs(i+1,j+1);  
    dfs(i-1,j-1);  
    dfs(i-1,j+1);  
    dfs(i+1,j-1);
    //搜索的目的只为了标记  
}  
  
int main()  
{  
    //freopen("E:\\in.txt","r",stdin);  
    //freopen("E:\\out.txt","w",stdout);  
    while(cin>>m>>n)  
    {  
      if(!m)  break;  
      memset(map,0,sizeof(map));  
      memset(visited,0,sizeof(visited));  
      ans=0;  
      for(int i = 0; i < m; ++i)  
        for(int j = 0; j < n; ++j)  
             cin>>map[i][j];  
      for(int i = 0; i < m; ++i)  
         for(int j = 0; j < n; ++j)  
             if(!visited[i][j] && map[i][j] == '@')  
             {  
               ans++;  
//和第二种写法不同的地方 ans也是为了计数而第二种采用了把编号放到函数里面 
               dfs(i,j);  
//调用dfs的时候实际上visited数组已经被标记上了 所以循环在第二次执行到这的时候
//会少判断一些@因为if条件里面visited数组中已经发生了变化    
            }   
       cout<<ans<<endl;  
    }  
    return 0;  
} 
-------------------------------------------------------------
char pic[10][10];  
int dix[10][10];  
int r,c;  
void dfs(int i,int j,int f1){  
    if(i<0||i>=r||j<0||j>=c)return;  
    if(dix[i][j]!=0||pic[i][j]!='@')return;  
    dix[i][j]=f1;  
    for(int g=-1;g<=1;g++)  
     for(int h=-1;h<=1;h++)  
      if(g!=0||h!=0) dfs(i+g,j+h,f1);  
}  
int main(){  
    int f1=0;  
    freopen("in.txt","r",stdin);  
    freopen("out.txt","w",stdout);  
    while(scanf("%d%d",&r,&c)==2&&r&&c){  
     for(int i=0;i<r;i++)scanf("%s",pic[i]);   
//将一整行都放入pic[0]中，因为其是二维数组，则pic[0][0]就为第一个字符  
         for(int i=0;i<r;i++)  
          for(int j=0;j<c;j++)  
            if(pic[i][j]=='@'&&dix[i][j]==0) dfs(i,j,++f1); 
//这里的dfs相当于给dix相对应pic有@的位置标上访问标记 
            printf("%d",f1);   
    }  
} 
-------------------------------------------------------------------------
8皇后问题的最弱解 时间复杂度O(8!)
dfs我这里没用位或者没用单行数组去存那些信息
这里用二维数组好理解思维
直接上代码
#coding=utf-8
import numpy as np
cb=np.zeros((8,8))
#print cb
def check(x,y):#这个是检查函数 注意各种范围的取值
    for i in range(y):
        if cb[i][x]==1:
            return False
    #检查列
    for i in range(1,y+1):
        nx=x+i
        ny=y-i
        if nx>=0 and nx<=7 and ny>=0 and ny<=7:
            if cb[ny][nx]==1:
                return False
    #检查副对角线
    for i in range(1,y+1):
        nx=x-i
        ny=y-i
        if nx >= 0 and nx <=7 and ny >=0 and ny <= 7:
            if cb[ny][nx] == 1:
                return False
    #检查主对角线
    return True
def dfs(step):#step可以表征y的值也可以考虑递归的深度
    if step==8:
        print cb
        return
    for i in range(8):
        if check(i,step):
#一般的根式就是这样递归 如果用单行数组也可以保存相当的状态量
#如果用位的话空间复杂度会更小速度会更快 但是对于工业来说就是编码速度和逻辑速度会变慢
#如果时间允许可以使用位编程去降低空间复杂度和时间复杂度
            cb[step][i]=1
            dfs(step+1)
            #print cb
            cb[step][i]=0
dfs(0)
#dfs总结：就是对于递归的应用 只不过穷举的时候要想好树的模型 用图的搜索算法
#对于dfs内部的调用记得判定值是不是合法 比如上面的check()函数 以及下面的
#来判定是否出界
--------------------------------------------------------------------------
数房子问题
#coding=utf-8
import numpy as np
map=np.zeros((5,5))
#print map
map[1][1]=1
map[1][2]=1
map[2][2]=1
map[2][3]=1
map[3][4]=1
map[4][4]=1
ans=0
print map
def dfs(x,y):
    if x>5 or y>5 or x<0 or y<0:
        return #无路可走
    if map[y][x]==0:
        return #无路可走
    map[y][x]=0
    if x+1<=4:
        dfs(x+1,y)
    if x-1>=4:
        dfs(x-1,y)
    if y+1<=4:
        dfs(x,y+1)
    if y-1>=0:
        dfs(x,y-1)
for i in range(5):
    for j in range(5):
        if map[i][j]==1:
            dfs(j,i)
            ans+=1
print ans
print map
------------------------------------------------------------------------------
第七届蓝桥杯 剪邮票
'''
得到了错误答案 还差6种 可能是自己哪里想的不对
知道哪里不对了 
这里写了110种
但是 还有
[0 1 0] [0 1 0]
[1 1 1] [0 1 0]
[0 1 0] [1 1 1] 
这两种没考虑也就是说还少了2+4种 总共116种
这个故事告诉我们dfs选择的策略如果是线性的 一定要注意非线性的选择
也就是说在样例的时候得考虑那种基本图形的任何一个位置添加
实在不行就拿数学去解吧
'''
map=np.zeros((3,4))
#print map
def dfs(step,x,y):
    if step==4:
        map[y][x]=1
        print map
        map[y][x]=0
        #print x,y
        return
    map[y][x]=1
    if x+1<=3 and map[y][x+1]==0: #下一步只能踏出0
        dfs(step+1,x+1,y)
    if x-1>=0 and map[y][x-1]==0:
        dfs(step+1,x-1,y)
    if y+1<=2 and map[y+1][x]==0:
        dfs(step+1,x,y+1)
    if y-1>=0 and map[y-1][x]==0:
        dfs(step+1,x,y-1)
    map[y][x]=0

for x in range(4):
    for y in range(3):
        #print x,y
        dfs(0,x,y)
dfs相对于动态规划神奇的显得朴素 但是在穷举的时候的修剪枝叶(这个过程是真的烦人)
却能大大优化树从而减少时间复杂度 当然像是8皇后那种利用位操作或者一维数组
强行提升速度达到最快 我想就是 acm选手和正常选手不同的地方吧
强行dp应该也可以用来保存某些存在问题的某些参数
下面用dfs做一次走迷宫 当然最优的算法当然是用bfs求的最短路径
但dfs求得的路径一定最快 都有舍弃和取得 自行选择 此后dfs就暂时告一段落 转向dp
```

