<?xml version="1.0" encoding="UTF-8"?>
<CustomApplication xmlns="http://soap.sforce.com/2006/04/metadata">
    <customApplicationComponents>
        <alignment>right</alignment>
        <customApplicationComponent>LiveText_Panel</customApplicationComponent>
    </customApplicationComponents>
    <defaultLandingTab>standard-home</defaultLandingTab>
    <description>LiveText lets your customers have text conversations with your support agents-delivering true mobile support messaging. It improves customer satisfaction,increases agent productivity,and meets customers’ mobile needs by adding SMS to your support numbers.</description>
    <detailPageRefreshMethod>autoRefresh</detailPageRefreshMethod>
    <enableKeyboardShortcuts>false</enableKeyboardShortcuts>
    <enableMultiMonitorComponents>false</enableMultiMonitorComponents>
    <isServiceCloudConsole>true</isServiceCloudConsole>
    <keyboardShortcuts>
        <defaultShortcut>
            <action>FOCUS_CONSOLE</action>
            <active>true</active>
            <keyCommand>ESC</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_NAVIGATOR_TAB</action>
            <active>true</active>
            <keyCommand>V</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_DETAIL_VIEW</action>
            <active>true</active>
            <keyCommand>SHIFT+S</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_PRIMARY_TAB_PANEL</action>
            <active>true</active>
            <keyCommand>P</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_SUBTAB_PANEL</action>
            <active>true</active>
            <keyCommand>S</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_LIST_VIEW</action>
            <active>true</active>
            <keyCommand>N</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_FIRST_LIST_VIEW</action>
            <active>true</active>
            <keyCommand>SHIFT+F</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>FOCUS_SEARCH_INPUT</action>
            <active>true</active>
            <keyCommand>R</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>MOVE_LEFT</action>
            <active>true</active>
            <keyCommand>LEFT ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>MOVE_RIGHT</action>
            <active>true</active>
            <keyCommand>RIGHT ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>UP_ARROW</action>
            <active>true</active>
            <keyCommand>UP ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>DOWN_ARROW</action>
            <active>true</active>
            <keyCommand>DOWN ARROW</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>OPEN_TAB_SCROLLER_MENU</action>
            <active>true</active>
            <keyCommand>D</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>OPEN_TAB</action>
            <active>true</active>
            <keyCommand>T</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>CLOSE_TAB</action>
            <active>true</active>
            <keyCommand>C</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>REFRESH_TAB</action>
            <active>false</active>
            <keyCommand>SHIFT+R</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>ENTER</action>
            <active>true</active>
            <keyCommand>ENTER</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>EDIT</action>
            <active>true</active>
            <keyCommand>E</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>SAVE</action>
            <active>true</active>
            <keyCommand>CTRL+S</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>CONSOLE_LINK_DIALOG</action>
            <active>false</active>
            <keyCommand>U</keyCommand>
        </defaultShortcut>
        <defaultShortcut>
            <action>HOTKEYS_PANEL</action>
            <active>false</active>
            <keyCommand>SHIFT+K</keyCommand>
        </defaultShortcut>
    </keyboardShortcuts>
    <label>LiveText</label>
    <listPlacement>
        <location>full</location>
    </listPlacement>
    <listRefreshMethod>refreshList</listRefreshMethod>
    <logo>HeyWire/LiveText_Console_App_Logo.png</logo>
    <pushNotifications>
        <pushNotification>
            <fieldNames>LiveText__Status__c</fieldNames>
            <objectName>LiveText__Conversation_Header__c</objectName>
        </pushNotification>
    </pushNotifications>
    <saveUserSessions>true</saveUserSessions>
    <tab>standard-Account</tab>
    <tab>standard-Contact</tab>
    <tab>standard-Case</tab>
    <tab>standard-Lead</tab>
    <tab>Conversation_Header__c</tab>
    <workspaceMappings>
        <mapping>
            <tab>standard-Case</tab>
        </mapping>
        <mapping>
            <tab>standard-Contact</tab>
        </mapping>
        <mapping>
            <tab>standard-Lead</tab>
        </mapping>
        <mapping>
            <tab>standard-Account</tab>
        </mapping>
        <mapping>
            <tab>Conversation_Header__c</tab>
        </mapping>
    </workspaceMappings>
</CustomApplication>