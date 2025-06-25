#~/.dotfiles/modules/thunderbird.nix
{ config, lib, pkgs, ... }:
{
  home.file = {
    ".thunderbird/default/chrome/userChrome.css".text = ''
      /*******Move tool bar above unified bar*******/
      toolbar#toolbar-menubar {
        Order:            -1 !important;
        background-color: #6D859C !important;  /* Color of menu bar */
        color:            white   !important;  /* Color of the text - if needed */
        padding-top:      0px     !important;
        padding-bottom:   0px     !important;
        margin:           0px     !important;
      }

      /***** Move window controls up to the menu bar ******/
      .titlebar-buttonbox-container { position: fixed;
        top: 0px; 
        right: 0px; 
        height: 19px !important;
        color:            white   !important; 
        /******** adjust if necessary **********/ 
      }

      /******Adjust and color unified toolbar******/
      #unifiedToolbar {
        height:  32px  !important;
        padding-block:   1px  !important;
        margin-block:    0px  !important;
        background:  #6D859C  !important;
        color: white  !important;
      }

      /*****Make the hover color transparent******/
      *|*:root {
        --listbox-hover: transparent !important;
      }
      .container:hover { background-color: transparent !important;
      }
      tr[is="thread-row"]:hover {
      background-color: transparent !important;
      }

      /*******Background color on folder list******/
      #folderPane,
      #folderPaneHeaderBar { background-color: #E4E4E6 !important; }
      
      /******Fix the new message button*******/
      #folderPaneWriteMessage { background-color: #6D859C !important; border: 2px solid white !important; color: white !important; }
        
      /*******Change universal fonts *******/
      *{ font-family: Aptos !important; }

      /*******Color selected items*******/
      li.selected > .container {
      color: black !important;
      background-color: #6D859C !important;

      [is="tree-view-table-body"] > .selected {
      color: black !important;
      background-color: #6D859C !important;
      }

      .tree-table,
      .card-container {
      background-color: #f0f0f0 !important;
      }

      .card-container {
        background-color: var(--tag-color) !important;
      }

      /*******Detailed Colors*******/
      :root {
        
        /* Specify colors for unread messages */
        
        /*default*/
        --text: #174a70;
        --button-0: #174a70;
        --bg: #f4f4f5;
        --border: #ffffff;
        
        /*hover*/
        --text-hover: #174a70;
        --button-hover-0: #174a70;
        --bg-hover: #f4f4f5;
        --border-hover: #ffffff;
        
        /*selected*/
        --text-select: #174a70;
        --button-select-0: #174a70;
        --bg-select: #f4f4f5;
        --border-select: #ffffff;

        /*current*/
        --text-current: #174a70;
        --button-current-0: #174a70;
        --bg-current: #f4f4f5;
        --border-current: #ffffff;
        
        /*current and selected*/
        --text-current-selected: #174a70;
        --button-current-selected-0: #174a70;
        --bg-current-selected: #f4f4f5;
        --border-current-selected: #ffffff;
        
        /*selected-indicator*/
        --indicator-bg: #174a70;
        --indicator-bd: #174a70;
        
        /* Specify colors for new messages */
        /*default*/
        --new-text: #174a70;
        --new-button-0: #ba0006;
        --new-bg: #f4f4f5;
        --new-border: #ffffff;

        /*hover*/
        --new-text-hover: #174a70;
        --new-button-hover-0: #ba0006;
        --new-bg-hover: #f4f4f5;
        --new-border-hover: #ffffff;

        /*selected*/
        --new-text-select: #174a70;
        --new-button-select-0: #ba0006;
        --new-bg-select: #f4f4f5;
        --new-border-select: #ffffff;

        /*current*/
        --new-text-current: #174a70;
        --new-button-current-0: #ba0006;
        --new-bg-current: #f4f4f5;
        --new-border-current: #ffffff;

        /*current and selected*/
        --new-text-current-selected: #174a70;
        --new-button-current-selected-0: #ba0006;
        --new-bg-current-selected: #f4f4f5;
        --new-border-current-selected: #ffffff;

        /*selected-indicator*/
        --new-indicator-bg: #174a70;
        --new-indicator-bd: #174a70;

        /* Specify colors for read messages */

        /*default*/
        --read-text: #000000;
        --read-button-0: transparent;
        --read-bg: #ffffff;
        --read-border: transparent;

        /*hover*/
        --read-text-hover: #000000;
        --read-button-hover-0: transparent;
        --read-bg-hover: #ffffff;
        --read-border-hover: #ffffff;

        /*selected*/
        --read-text-select: #174a70;
        --read-button-select-0: tranparent;
        --read-bg-select: #e6e6e6;
        --read-border-select: #e6e6e6;

        /*current*/
        --read-text-current: #fa36f7;
        --read-bg-current: #fa36f7;
        --read-button-current-0: transparent;
        --read-border-current: #e6e6e6;

        /*current and selected*/
        --read-text-current-selected: #174a70;
        --read-button-current-selected-0: transparent;
        --read-bg-current-selected: #e6e6e6;
        --read-border-current-selected: #e6e6e6;

        /*selected-indicator*/
        --read-indicator-bg: #174a70;
        --read-indicator-bd: #174a70;
      }

      /*Table*/

      /*unread*/
      #threadTree tbody [data-properties~="unread"] {
        
        /*Default*/
        font-weight: Bold !important;
        color: var(--text) !important; /* Text color */
        background-color: var(--bg) !important; /* Background color */
        outline: 0px solid var(--border) !important; /* Border color */

        .tree-view-row-unread > .tree-button-unread > img {
          fill: var(--button-0) !important;
          stroke: var(--button-0) !important; /* button color */
        }

        /*hover*/
        &:hover {
          color: var(--text-hover) !important;      /* Text color */
            background-color: var(--bg-hover) !important;      /* Background color */
            outline: 0px solid var(--border-hover) !important;      /* Border color */
          
            .tree-view-row-unread > .tree-button-unread > img {
              fill: var(--button-hover-0) !important;
              stroke: var(--button-hover-0) !important;        /* button color */
            }
        }
        
        /*selected*/
        &.selected {
          color: var(--text-select) !important;    /* Text color */
          background-color: var(--bg-select) !important;    /* Background color */
          outline: 1px solid var(--border-select) !important;    /* Border color */

          .tree-view-row-unread > .tree-button-unread > img {
            fill: var(--button-select-0) !important;
            stroke: var(--button-select-0) !important;      /* button color */
          }
        }
        
        /*current*/
        &.current {
          color: var(--text-current) !important;    /* Text color */
          background-color: var(--bg-current) !important;    /* Background color */
          outline: 1px solid var(--border-current) !important;    /* Border color */

          .tree-view-row-unread > .tree-button-unread > img {
            fill: var(--button-current-0) !important;
            stroke: var(--button-current-0) !important;      /* button color */
          }
          
          /*selected*/
          &.selected {
            color: var(--text-current-selected) !important;    /* Text color */
            background-color: var(--bg-current-selected) !important;    /* Background color */
            outline: 1px solid var(--border-current-selected) !important;    /* Border color */

            .tree-view-row-unread > .tree-button-unread > img {
              fill: var(--button-current-selected-0) !important;
              stroke: var(--button-current-selected-0) !important;      /* button color */
            }
          }
          
        }
      }

      /*read*/ #threadTree tbody [data-properties ~="read"] {

        /*Default*/
       
        color: var(--read-text) !important;  /* Text color */
        background-color: var(--read-bg) !important;  /* Background color */
        outline: 0px solid var(--read-border) !important;  /* Border color */


        /*hover*/
        &:hover {
          color: var(--read-text-hover) !important;    /* Text color */
          background-color: var(--read-bg-hover) !important;    /* Background color */
          outline: 0px solid var(--read-border-hover) !important;    /* Border color */


        }

        /*selected*/
        &.selected {
          color: var(--read-text-select) !important;    /* Text color */
          background-color: var(--read-bg-select) !important;    /* Background color */
          outline: 1px solid var(--read-border-select) !important;    /* Border color */
          
        }
        
        /*current*/
        &.current {
          color: var(--read-text-current) !important;    /* Text color */
          background-color: var(--read-bg-current) !important;    /* Background color */
          outline: 1px solid var(--read-border-current) !important;    /* Border color */
          
          /*selected*/
          &.selected {
            color: var(--read-text-current-selected) !important;      /* Text color */
            background-color: var(--read-bg-current-selected) !important;      /* Background color */
            outline: 1px solid var(--read-border-current-selected) !important;      /* Border color */
            
          }
          
        }
      }

/*******Fix tabs***********/
#tabmail-arrowscrollbox { background-color: #E4E4E6 !important; }
 
.tab-line[selected=true] { background-color:transparent !important; }
 
:root { --tabs-toolbar-background-color: #E4E4E6 !important; }

/******Fix New Event and New Task buttons***********/
#sidePanelNewEvent { background-color: #E4E4E6 !important; border: 1px solid white !important; color: white !important; }
 
#sidePanelNewTask { background-color: #E4E4E6 !important; border: 1px solid white !important; color: white !important; }

    '';

    ".thunderbird/default/chrome/userContent.css".text = ''
      blockquote[type=cite] {
        padding-bottom: 0 !important;
        padding-top: 0 !important;
        padding-left: 0 !important;
        border-left: none !important;
        border-right: none !important;
      }

      @-moz-document url-prefix("about:addressbook") {
        #booksPaneCreateContact {background-color: #435468 !important; border: 1px solid white !important; color: white !important;
      }
    '';
  };
}
