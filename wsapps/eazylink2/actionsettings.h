#ifndef ACTIONSETTINGS_H
#define ACTIONSETTINGS_H

#include <QFrame>
#include<QSettings>

namespace Ui {
class ActionSettings;
}

namespace Action_Settings{

    extern const int Action_db_version;

    extern const char *ActKey_DBLCLK_HOSTFILE;// = "DBLCLKDSK";
    extern const char *ActKey_DBLCLK_Z88FILE; // = "DBLCLKZ88";
    extern const char *ActKey_RX_FROMZ88;     // = "RXFROMZ88";
    extern const char *ActKey_TX_TOZ88;       // = "TXTOZ88";

    extern const char *DEFAULT_FILESPEC_ARGS;
    extern const char *DEFAULT_Z88_DESTSPEC;//  = "%P/%F";
    extern const char *DEFAULT_FULLFSPEC;   //  = "%P/%F";
}

class ActionRule : public QString {

public:
    enum Rule_IDs{
        NONE,
        OPEN_WITH_EXT_APP,
        IGNORE,
        TRANSFER_FILE,
        CONVERT_CRLF,
        BINARY_MODE
    };

    ActionRule(const QString &desc, const QString &def_args, Rule_IDs flags = NONE);
    ActionRule(const char *desc, const char *def_args = "", Rule_IDs flags = NONE);

    /**
      * The Default Command args used when user adds New Item
      */
    QString m_defaultArgs;

    Rule_IDs m_RuleID;
};

typedef QList<ActionRule> ActionRuleList_t;
typedef QList<QStringList> StringLList_t;

static const StringLList_t empty_list;

/**
  * Container to Handle a File Action.
  */
class FileAction {

public:
    explicit FileAction(const QString &KeyName, const QString &descStr, const ActionRuleList_t &avail_actions, const StringLList_t &defaults = empty_list);
    ~FileAction();

    const QString &get_KeyName()const {return m_KeyName;}
    const QString &get_descStr()const {return m_descStr;}
    const ActionRuleList_t &getAvail_Rules() const {return m_AvailRules;}
    const StringLList_t &getDefaults() const{return m_defaultFilters;}

    int get_indexOf(const QString & RuleStr) const;
    const ActionRule *get_ActionRule(const QString &RuleStr) const;
protected:

    QString m_KeyName;
    QString m_descStr;

    ActionRuleList_t m_AvailRules;

    StringLList_t m_defaultFilters;
};

typedef QList<FileAction> FileActionList_T;


class ActionSettings : public QFrame
{
    Q_OBJECT
    
public:
    explicit ActionSettings(QWidget *parent = NULL);
    ~ActionSettings();

    enum ft_columns{
        ft_filename,
        ft_extension,
        ft_action,
        ft_args,
        ft_columns
    };

    enum DblClk_Actions{
        Do_Nothing = 1001,
        Transfer,
        OpenFile
    };

    enum ActionKeys{
        Action_DBL_CLICK_DESK,
        Action_DBL_CLICK_Z88,
        Action_RX_FROM_Z88,
        Action_TX_TO_Z88
    };

    int load_Action_RuleList(int index);
    int load_Action_RuleList(const FileAction &fa, StringLList_t &ruleList);
    int reLoadActionRulesList();


    int save_ActionList();
    int save_ActionList(int index);
    int save_ActionList(QSettings &settings);
    int save_ActionList(QSettings &settings, const FileAction &fa);

    void Append_FileAction(const FileAction & fa);

    int findAction(const QString &ActionKey, const QString Fspec);

    int findAction(const QString &ActionKey, const QString Fspec, QString &CmdLine);

    const ActionRule *findActionRule(const QString &ActionKey, const QString Fspec, QString &CmdLine);

private slots:
    void ft_itemSelectionChanged();
    void ft_deleteItem();
    void ft_itemUp();
    void ft_itemDn();
    int ft_addItem(const QString &fname = "*", const QString &ext = "*");

    void action_itemSlectionChanged(const QString &);
    void cellDataCHanged(int , int );
    void cellDblClicked(int row, int col);


private:
    void set_Defaults(const StringLList_t &defaults);

    FileAction *getFileAction(const QString &ActionStr);

    bool isMatch(const QString &fspec, const QStringList &ActionRule);

    QString &expandCmdline(const QString &cmdline, const QString &fspec, QString &result);

    Ui::ActionSettings *ui;

    QStringList m_ft_items;

    FileActionList_T m_Actions;

    bool m_TableChanged;

    int m_lastActionSel;

};

#endif // ACTIONSETTINGS_H