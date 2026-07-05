```dataviewjs
// 1. 定义日记文件的来源路径
// 请将 "日记" 替换为你实际存放日记的文件夹名称
const diaryFolder = '"02-area/daily"';
// 2. 使用 Dataview 查询所有日记文件中的任务
const tasks = dv.pages(diaryFolder).file.tasks;
// 3. 过滤出未完成且包含 #uncomplete 标签的任务
const filteredTasks = tasks
    .where(t => !t.completed)              // 只取未完成的任务
    .where(t => t.tags.includes("#uncomplete")); // 必须有 #uncomplete 标签
// 4. 展示结果
if (filteredTasks.length === 0) {
    // 如果没有找到任何任务，显示提示信息
    dv.paragraph("🎉 太棒了！没有找到带有 #uncomplete 标签的未完成任务。");
} else {
    // 否则，以任务列表的形式展示所有任务
    // 列表会显示任务文本、所属文件，并按文件进行分组
    dv.taskList(filteredTasks, false);
}
```
