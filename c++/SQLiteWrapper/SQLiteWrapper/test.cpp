#include <stdio.h>

#include <io.h>
#include <vector>
#include <AtlBase.h>
#include <time.h>

#include "process.h"
#include "SQLite.h"
void SqliteOperate();

int main()
{

	SqliteOperate();
	system("pause");
	return 0;
}

void SqliteOperate()
{
	TCHAR *szDbPath = _T("Book.db");

	::DeleteFile(szDbPath);

	SQLite sqlite;

	// �򿪻򴴽����ݿ�
	//******************************************************
	if (!sqlite.Open(szDbPath))
	{
		_tprintf(_T("%s\n"), sqlite.GetLastErrorMsg());
		return;
	}
	//******************************************************

	// �������ݿ��
	//******************************************************
	TCHAR sql[512] = { 0 };
	_stprintf(sql, _T("%s"),
		_T("CREATE TABLE [Book] (")
		_T("[id] INTEGER NOT NULL PRIMARY KEY, ")
		_T("[name] NVARCHAR(20), ")
		_T("[author] NVARCHAR(20), ")
		_T("[catagory_id] INTEGER REFERENCES [Category]([id]), ")
		_T("[abstruct] NVARCHAR(100) ,")
		_T("[path] NVARCHAR(50), ")
		_T("[image] BLOB);")
		_T("CREATE INDEX [Book_id] ON [Book] ([id]);")
		);
	if (!sqlite.ExcuteNonQuery(sql))
	{
		printf("Create database table failed...\n");
	}
	//******************************************************

	// �������ݡ���ͨ��ʽ��
	DWORD dwBeginTick = GetTickCount();
	//******************************************************
	// ��һ���Բ��������¼ʱ�򣬲�������ķ�ʽ�����Ч��
	sqlite.BeginTransaction();
	// ������������
	for (int i = 0; i<1000; i++)
	{
		memset(sql, 0, sizeof(sql));
		_stprintf(sql, _T("insert into Book(name,author,catagory_id) values('�����%d','Ī��',1)"), i);
		if (!sqlite.ExcuteNonQuery(sql))
		{
			_tprintf(_T("%s\n"), sqlite.GetLastErrorMsg());
			break;
		}
	}
	// �ύ����
	sqlite.CommitTransaction();
	printf("Insert Data Take %dMS...\n", GetTickCount() - dwBeginTick);
	//******************************************************


	// �������ݡ�ͨ�������󶨵ķ�ʽ���ύ��������ʱ�����������ͨģʽЧ�ʸ��ߣ����Լ45%����ͬʱ��֧�ֲ�����������ݡ�
	dwBeginTick = GetTickCount();
	//******************************************************
	// ��һ���Բ��������¼ʱ�򣬲�������ķ�ʽ�����Ч��
	sqlite.BeginTransaction();
	memset(sql, 0, sizeof(sql));
	_stprintf(sql, _T("insert into Book(name,author,catagory_id,image) values(?,'����',?,?)"));
	SQLiteCommand cmd(&sqlite, sql);
	// ������������
	for (int i = 0; i<1000; i++)
	{
		TCHAR strValue[16] = { 0 };
		_stprintf(strValue, _T("���Ĺ�%d"), i);
		// �󶨵�һ��������name�ֶ�ֵ��
		cmd.BindParam(1, strValue);
		// �󶨵ڶ���������catagory_id�ֶ�ֵ��
		cmd.BindParam(2, 20);
		BYTE imageBuf[] = { 0xff, 0xff, 0xff, 0xff };
		// �󶨵�����������image�ֶ�ֵ,���������ݣ�
		cmd.BindParam(3, imageBuf, sizeof(imageBuf));
		if (!sqlite.ExcuteNonQuery(&cmd))
		{
			_tprintf(_T("%s\n"), sqlite.GetLastErrorMsg());
			break;
		}
	}
	// ���cmd
	cmd.Clear();
	// �ύ����
	sqlite.CommitTransaction();
	printf("Insert Data Take %dMS...\n", GetTickCount() - dwBeginTick);
	//******************************************************

	// ��ѯ
	dwBeginTick = GetTickCount();
	//******************************************************
	memset(sql, 0, sizeof(sql));
	_stprintf(sql, _T("%s"), _T("select * from Book where name = '���Ĺ�345'"));

	SQLiteDataReader Reader = sqlite.ExcuteQuery(sql);

	int index = 0;
	int len = 0;
	while (Reader.Read())
	{
		_tprintf(_T("***************����%d����¼��***************\n"), ++index);
		_tprintf(_T("�ֶ���:%s �ֶ�ֵ:%d\n"), Reader.GetName(0), Reader.GetIntValue(0));
		_tprintf(_T("�ֶ���:%s �ֶ�ֵ:%s\n"), Reader.GetName(1), Reader.GetStringValue(1));
		_tprintf(_T("�ֶ���:%s �ֶ�ֵ:%s\n"), Reader.GetName(2), Reader.GetStringValue(2));
		_tprintf(_T("�ֶ���:%s �ֶ�ֵ:%d\n"), Reader.GetName(3), Reader.GetIntValue(3));
		_tprintf(_T("�ֶ���:%s �ֶ�ֵ:%s\n"), Reader.GetName(4), Reader.GetStringValue(4));
		// ��ȡͼƬ�������ļ�
		const BYTE *ImageBuf = Reader.GetBlobValue(6, len);
		_tprintf(_T("*******************************************\n"));
	}
	Reader.Close();
	printf("Query Take %dMS...\n", GetTickCount() - dwBeginTick);
	//******************************************************

	// �ر����ݿ�
	sqlite.Close();
}