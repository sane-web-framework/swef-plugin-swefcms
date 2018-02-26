<?php

namespace Swef;

class SwefCMS extends \Swef\Bespoke\Plugin {


/*
    PROPERTIES
*/

    public $children    = array ();
    public $collection;
    public $collections;
    public $dashboardOption;
    public $error;
    public $exportItems = array (); // UUIDs for items undergoing export
    public $exportList  = array (); // Items undergoing export
    public $item;
    public $languages   = array (); // Deployed in this collection
    public $markdown;               // Markdown item/language currently in focus
    public $mothers     = array ();
    public $viewing;  // Set if viewing with page event handlers

/*
    EVENT HANDLER SECTION
*/

    public function __construct ($page) {
        // Always construct the base class - PHP does not do this implicitly
        parent::__construct ($page,'\Swef\SwefCMS');
    }

    public function __destruct ( ) {
        // Always destruct the base class - PHP does not do this implicitly
        parent::__destruct ( );
    }

    public function _on_pageIdentifyBefore ( ) {
        $this->viewing = SWEF_BOOL_TRUE;
        if (strstr($this->page->requestURI,swefcms_slug_dir_separator)===SWEF_BOOL_FALSE) {
            return SWEF_BOOL_TRUE;
        }
        $uuid = explode (SWEF_STR__FSLASH,$_SERVER['REQUEST_URI']);
        $uuid = array_pop ($uuid);
        $uuid = explode (swefcms_slug_dir_separator,$uuid);
        $uuid = array_pop ($uuid);
        $this->page->diagnosticAdd ('UUID = '.$uuid);
        if (strlen($uuid)<swefcms_slug_uuid_min_length) {
            $this->page->diagnosticAdd ('    UUID too short to be valid');
            return SWEF_BOOL_TRUE;
        }
        if (!preg_match(swefcms_uuid_preg_match,$uuid)) {
            $this->page->diagnosticAdd ('    UUID contains invalid characters');
            return SWEF_BOOL_TRUE;
        }
        $this->collectionsLoad ();
        $this->itemSelect ($uuid);
        $this->markdownBrowse ();
        $this->page->diagnosticAdd ('UUID = '.$uuid);
        if (!$this->item) {
            $this->page->diagnosticAdd ('    Item not found: UUID = '.$uuid);
            $this->page->diagnosticAdd ('    Not intervening');
            return SWEF_BOOL_TRUE;
        }
        $this->page->diagnosticAdd ('    Intervening');
        return SWEF_BOOL_TRUE;
    }

    public function _on_pageScriptBefore ( ) {
        return SWEF_BOOL_TRUE;
    }



/*
    DASHBOARD SECTION
*/


    public function _dashboard ( ) {
        require_once swefcms_file_dash;
    }

    public function _info ( ) {
        $info   = __FILE__.SWEF_STR__CRLF;
        $info  .= SWEF_COL_CONTEXT.SWEF_STR__EQUALS;
        $info  .= $this->page->swef->context[SWEF_COL_CONTEXT];
        return $info;
    }

/*
    SUPPORTING METHODS
*/

    public function apiItemProperties ($args) {
        if (!is_array($args) || !array_key_exists(SWEF_INT_0,$args)) {
            return SWEF_HTTP_STATUS_CODE_444;
        }
        $this->collectionsLoad ();
        $item_uuid = $args[0];
        $this->itemSelect ($item_uuid);
        if (!$this->item) {
            $this->page->diagnosticAdd ('Unable to select item UUID='.$item_uuid);
            return SWEF_HTTP_STATUS_CODE_404;
        }
        $item = array ();
        foreach ($this->item as $property=>$value) {
            if (!is_array($value)) {
                $item[$property] = $value;
            }
        }
        return $item;
    }

    public function apiItemUpdate ($args) {
        if (!is_array($args) || !array_key_exists(SWEF_INT_2,$args)) {
            return SWEF_HTTP_STATUS_CODE_444;
        }
        $this->collectionsLoad ();
        $item_uuid = $args[0];
        $active    = $args[1];
        $order     = $args[2];
        $updater   = $this->page->swef->user->uuid;
        $updated   = $this->page->swef->moment->gmt (SWEF_DATETIME_FORMAT_TIMESTAMP);
        $this->itemSelect ($item_uuid);
        if (!$this->item) {
            $this->page->diagnosticAdd ('Unable to select item UUID='.$item_uuid);
            return SWEF_HTTP_STATUS_CODE_404;
        }
        if (!$this->item[swefcms_col_collection][swefcms_col_may_update]) {
            $this->page->diagnosticAdd ('Usergroup may not update item='.$item_uuid);
            return SWEF_HTTP_STATUS_CODE_403;
        }
        $update    = $this->page->swef->db->dbCall (
            swefcms_call_item_update
           ,$item_uuid
           ,$active
           ,$order
           ,$updater
           ,$updated
        );
        if (!$update) {
            return SWEF_HTTP_STATUS_CODE_555;
        }
        $this->item[swefcms_col_active]     = $active;
        $this->item[swefcms_col_order]      = $order;
        $this->item[swefcms_col_updater]    = $updater;
        $this->item[swefcms_col_updated]    = $updated;
        return array (swefcms_col_item_uuid=>$item_uuid);
    }

    public function apiRelationAdd ($args) {
        if (!is_array($args) || !array_key_exists(SWEF_INT_1,$args)) {
            return SWEF_HTTP_STATUS_CODE_444;
        }
        $this->collectionsLoad ();
        $item_uuid      = $args[0];
        $relation_uuid  = $args[1];
        $args           = array (
            $item_uuid,
            $this->item[swefcms_col_active],
            $this->item[swefcms_col_order]
        );
        if (!is_array($error=$this->apiItemUpdate($args))) {
            return $error;
        }
        $insert         = $this->page->swef->db->dbCall (
            swefcms_call_relation_add
           ,$item_uuid
           ,$relation_uuid
        );
        if (!$insert) {
            return SWEF_HTTP_STATUS_CODE_555;
        }
        return array (swefcms_col_item_uuid=>$item_uuid);
    }

    public function apiRelationRemove ($args) {
        if (!is_array($args) || !array_key_exists(SWEF_INT_1,$args)) {
            return SWEF_HTTP_STATUS_CODE_444;
        }
        $this->collectionsLoad ();
        $item_uuid      = $args[0];
        $relation_uuid  = $args[1];
        $args           = array (
            $item_uuid,
            $this->item[swefcms_col_active],
            $this->item[swefcms_col_order]
        );
        if (!is_array($error=$this->apiItemUpdate($args))) {
            return $error;
        }
        $delete         = $this->page->swef->db->dbCall (
            swefcms_call_relation_remove
           ,$item_uuid
           ,$relation_uuid
        );
        if (!$delete) {
            return SWEF_HTTP_STATUS_CODE_555;
        }
        return array (swefcms_col_item_uuid=>$item_uuid);
    }

    public function collectionCreate ( ) {
// NEEDS REWRITING
// INCLUDING MOTHER MAY_CREATE check
        if (!$this->page->_POST('swefcms-collection-create')) {
            return;
        }

        $slug   = SWEF_STR__FSLASH.$this->page->_POST('swefcms-slug');
        $taken = $this->page->swef->db->dbCall (
            swefcms_call_slugtaken
           ,$slug
        );
        if (count($taken)) {
            $this->notify ('Could not create item - slug is already taken');
            return;
        }
        else {
            if (!is_array($this->page->_POST('swefcms-collection'))) {
                $this->notify ('Could not create Collection - data was not posted');
                return;
            }
            $now    = $this->page->swef->moment->data (SWEF_DATETIME_FORMAT_TIMESTAMP);
            $insert = $this->page->swef->db->dbCall (
                swefcms_call_itemcreate
               ,$now
               ,$this->page->swef->user->email
               ,$now
               ,$this->page->swef->user->email
               ,$this->page->_POST('swefcms-title')
               ,$this->page->_POST('swefcms-slug')
               ,$this->page->_POST('swefcms-markdown')
            );
            if (!$insert) {
                $this->notify ('Could not create collection item');
                return;
            }
            foreach ($this->page->_POST('swefcms-collection') AS $row) {
                $insert = $this->page->swef->db->dbCall (
                    swefcms_call_collectioncreate
                );
                if (!$insert) {
                    $this->notify ('Could not create collection');
                    return;
                }
            }
            $this->notify ('Created new collection '.$uuid);
            $this->page->reload ('?c=\Swef\SwefCMS&u='.urlencode($uuid));
        }
    }

    public function collectionSelect ($item_uuid) {
        $collections        = $this->identifyCollections ($item_uuid);
        if (!count($collections)) {
            $this->page->diagnosticAdd ('No collections are available');
        }
        foreach ($this->page->swef->user->memberships as $m) {
            foreach ($collections as $c) {
                $this->page->diagnosticAdd ('Comparing '.$m[SWEF_COL_USERGROUP].' with "'.$c[swefcms_col_title].'"');
                if ($c[SWEF_COL_USERGROUP]==$m[SWEF_COL_USERGROUP]) {
                    $this->page->diagnosticAdd ('    This usergroup is allowed');
                    return $c;
                }
            }
        }
        return SWEF_BOOL_FALSE;
    }

    public function collectionUpdate ( ) {
//        if ($this->page->_POST('swefcms-collection')) {
//          if ($uuid=$this->collectionUpdate()) {
//              $this->page->reload ('?c=\Swef\SwefCMS&o=collection&u='.urlencode($uuid));
//          }
//      }
    }

    public function collectionsLoad ( ) {
        if ($this->collections) {
            return SWEF_BOOL_TRUE;
        }
        $this->collections  = $this->page->swef->lookupLoad (
            swefcms_collections_lookup
           ,swefcms_call_collections
           ,$this->page->swef->context[SWEF_COL_LANGUAGE]
        );
        if (!is_array($this->collections) || !count($this->collections)) {
            $this->notify ('Could not load collection data (or there was no data)');
            return SWEF_BOOL_FALSE;
        }
        return SWEF_BOOL_TRUE;
    }

    public function collectionsView ( ) {
        $collections = array ();
        if (!is_array($this->collections)) {
            return $collections;
        }
        foreach ($this->collections as $c) {
            if (!array_key_exists($c[swefcms_col_item_uuid],$collections)) {
                $collections[$c[swefcms_col_item_uuid]] = $c;
                $collections[$c[swefcms_col_item_uuid]][SWEF_COL_USERGROUPS] = array ();
            }
            array_push ($collections[$c[swefcms_col_item_uuid]][SWEF_COL_USERGROUPS],$c[SWEF_COL_USERGROUP]);
        }
        return $collections;
    }

    public function dashboardLoad ( ) {
        $this->collectionsLoad ();
        $this->dashboardOption      = $this->page->_GET (SWEF_GET_OPTION);
        if (!in_array($this->dashboardOption,swefcms_dashboard_options_valid)) {
            $this->dashboardOption  =  SWEF_STR__EMPTY;
        }
    }

    public function dashboardOption ($option) {
        // Always identify the item (preferred language by GET is optional)
        $this->itemSelect (
            $this->page->_GET (swefcms_get_uuid),
            $this->page->_GET (swefcms_get_language)
        );
        // Create, update, delete
        if($option=='collectionCreate') {
            $this->collectionCreate ();
        }
        elseif($option=='collectionUpdate') {
            $this->collectionUpdate ();
        }
        elseif($option=='itemCreate'){
            $this->itemCreate ();
        }
        // Views where we have enough data
        if($option=='collections') {
            require_once swefcms_file_option_collections;
            return;
        }
        if($option=='collection') {
            require_once swefcms_file_option_collection;
            return;
        }
        // Identify markdown by language and version
        $this->markdownSelect (
            $this->page->_GET(swefcms_get_language),
            $this->page->_GET(swefcms_get_version)
        );
        // Views needing all the data
        if ($option=='item') {
            require_once swefcms_file_option_item;
            return;
        }
        if ($option=='markdown') {
            if (!$this->item[swefcms_col_item_uuid]) {
                $this->item     = null;
                $this->markdown = null;
            }
            require_once swefcms_file_option_markdown;
            return;
        }
    }

    public function export ($item,$language) {
        if (in_array($item[swef_col_item_uuid],$this->exportItems)) {
            return;
        }
        $children = $item[swef_col_children];
        unset ($item[swef_col_mother]);
        unset ($item[swef_col_children]);
        foreach ($children as $tmp) {
        }
    }

    public function identifyCollections ($item_uuid) {
        if (!is_array($this->collections)) {
            return array ();
        }
        $cs = array ();
        foreach ($this->collections as $c) {
            if ($c[SWEF_COL_CONTEXT]!=$this->page->swef->context[SWEF_COL_CONTEXT]) {
                continue;
            }
            if ($c[swefcms_col_item_uuid]!=$item_uuid) {
                continue;
            }
            foreach ($this->page->swef->user->memberships as $m) {
                array_push ($cs,$c);
            }
        }
        return $cs;
    }

    public function itemCreate ( ) {
        if (!$this->page->_POST('swefcms-item-create')) {
            return;
        }
        $mother = $this->page->_POST('swefcms-mother');
        // Slug construction needs reworking
        $now    = $this->page->swef->moment->data (SWEF_DATETIME_FORMAT_TIMESTAMP);
        $uuid   = $this->page->swef->db->dbCall(SWEF_CALL_UUID)[0][SWEF_COL_UUID];
        $insert = $this->page->swef->db->dbCall (
            swefcms_call_itemcreate
           ,$uuid
           ,$now
           ,$this->page->swef->user->email
           ,$now
           ,$this->page->swef->user->email
           ,swefcms_default_title
           ,$slug
           ,SWEF_STR__EMPTY
        );
        if ($insert) {
            return $slug;
            $this->page->reload ('?c=\Swef\SwefCMS&o=item&u='.urlencode($uuid));
        }
        $this->notify ('Could not create item - try again');
    }

    public function itemSelect ($uuid,$pref_lang=null) {
        if ($this->item) {
            return SWEF_BOOL_TRUE;
        }
        if (!$pref_lang) {
            $pref_lang                      = $this->page->swef->context[SWEF_COL_LANGUAGE];
        }
        $this->page->diagnosticAdd ('Selecting item '.$uuid);
        $item                               =  $this->page->swef->db->dbCall (
            swefcms_call_item
           ,$uuid
        );
        if (!is_array($item) || !count($item)) {
            $this->notify ('Item not found [1]: UUID='.$uuid);
            $this->page->diagnosticAdd ('    not found');
            return SWEF_BOOL_FALSE;
        }
        $this->page->diagnosticAdd ('    found');
        $item                               = $item[0];
        $item[SWEF_COL_LANGUAGES]           = explode (SWEF_STR__COMMA,$item[SWEF_COL_LANGUAGES]);
        $this->page->diagnosticAdd ('Identifying markdown versions');
        $item[swefcms_col_markdowns]        =  $this->page->swef->db->dbCall (
            swefcms_call_markdowns
           ,$uuid
           ,$pref_lang
        );
        if (!$item[swefcms_col_markdowns] || !count($item[swefcms_col_markdowns])) {
            $this->page->diagnosticAdd ('    not found');
            $this->notify ('Item not found [2]: UUID='.$uuid);
            return SWEF_BOOL_FALSE;
        }
        $this->page->diagnosticAdd (count($item[swefcms_col_markdowns]).' markdown variants found');
        $item[swefcms_col_markdowns] = $this->markdownsExtra ($item[swefcms_col_markdowns]);
        $try                                = $item;
        $i = 0;
        while ($i<swefcms_collection_sane_depth) {
            $this->page->diagnosticAdd ('    Item is '.$try[swefcms_col_item_uuid]);
            if ($try[swefcms_col_is_collection]) {
                $this->page->diagnosticAdd ('    Item is a collection');
                $item[swefcms_col_collection] = $this->collectionSelect ($try[swefcms_col_item_uuid]);
                if (!$item[swefcms_col_collection]) {
                    $this->page->diagnosticAdd ('    Although a collection, the data was not found');
                    $this->notify ('Item not found [3]: UUID='.$uuid);
                    return SWEF_BOOL_FALSE;
                }
                $this->page->diagnosticAdd ('    Collection retrieved');
            }
            $this->page->diagnosticAdd ('    Finding mother of '.$try[swefcms_col_item_uuid]);
            $try                                = $this->page->swef->db->dbCall (
                swefcms_call_item
               ,$try[swefcms_col_mother_uuid]
            );
            $try                                = $try[0];
            if ($i==SWEF_INT_0) {
                if ($try && count($try)) {
                    $this->page->diagnosticAdd ('Identifying mother markdown variants');
                    $try[swefcms_col_markdowns] =  $this->page->swef->db->dbCall (
                        swefcms_call_markdowns
                       ,$try[swefcms_col_item_uuid]
                       ,$this->page->swef->context[SWEF_COL_LANGUAGE]
                    );
                    if (!$try[swefcms_col_markdowns] || !count($try[swefcms_col_markdowns])) {
                        $this->page->diagnosticAdd ('    not found');
                        if (!$this->viewing) {
                            $this->notify ('Could not find markdown for mother '.$try[swefcms_col_item_uuid]);
                        }
                        $this->notify ('Item not found [4]: UUID='.$uuid);
                        return SWEF_BOOL_FALSE;
                    }
                    $try[swefcms_col_markdowns] = $this->markdownsExtra ($try[swefcms_col_markdowns]);
                    $item[swefcms_col_mother]   = $try;
                }
                else {
                    $item[swefcms_col_mother]   = null;
                }
                $this->page->diagnosticAdd ('    Mother added to data');
            }
            if (array_key_exists(swefcms_col_collection,$item)) {
                $this->page->diagnosticAdd ('    Both mother and collection added to data - finished');
                break;
            }
            if (!is_array($try) || !count($try)) {
                $this->page->diagnosticAdd ('        has no mother');
                $this->notify ('Item not found [5]: UUID='.$uuid);
                return SWEF_BOOL_FALSE;
            }
            $i++;
        }
        $this->page->diagnosticAdd ('Identifying children');
        $item[swefcms_col_children]   = $this->page->swef->db->dbCall (
            swefcms_call_children
           ,$item[swefcms_col_item_uuid]
           ,'en'
        );
        $this->page->diagnosticAdd (count($item[swefcms_col_children]).' children found');
        $this->page->diagnosticAdd ('Identifying related items');
        $item[swefcms_col_relations]  = $this->page->swef->db->dbCall (
            swefcms_call_relations
           ,$item[swefcms_col_item_uuid]
           ,$pref_lang
        );
        $this->page->diagnosticAdd (count($item[swefcms_col_relations]).' related items found');
        $this->item = $item;
        return SWEF_BOOL_TRUE;
    }

    public function markdownSelect ($language=SWEF_STR__EMPTY,$version=SWEF_INT_0) {
        if (!$this->item) {
            $this->notify ('Item not found [6]');
            return SWEF_BOOL_FALSE;
        }
        $markdowns          = array ();
        $languages          = array ();
        $versions           = array ();
        $this->markdown     = $this->item[swefcms_col_markdowns][SWEF_INT_0];
        foreach ($this->item[swefcms_col_markdowns] as $m) {
            if ($language && $m[SWEF_COL_LANGUAGE]==$language) {
                array_push ($markdowns,$m);
            }
            if (!in_array($m[SWEF_COL_LANGUAGE],$languages)) {
                array_push ($languages,$m[SWEF_COL_LANGUAGE]);
            }
            if (!in_array($m[swefcms_col_version],$versions)) {
                array_push ($versions,$m[swefcms_col_version]);
            }
        }
        if (array_key_exists(SWEF_INT_0,$markdowns)) {
            $this->markdown = $markdowns[SWEF_INT_0];
            if ($version) {
                foreach ($markdowns as $m) {
                    if ($m[swefcms_col_version]==$version) {
                        $this->markdown = $m;
                        break;
                    }
                }
            }
        }
        $src = $this->page->swef->db->dbCall (
            swefcms_call_markdown_source
           ,$this->markdown[swefcms_col_item_uuid]
           ,$this->markdown[SWEF_COL_LANGUAGE]
           ,$this->markdown[swefcms_col_version]
        );
        $src = $src[0];
        $this->markdown[swefcms_col_markdown] = $src[swefcms_col_markdown_source];
        $this->markdown[SWEF_COL_LANGUAGES]   = $languages;
        $this->markdown[swefcms_col_versions] = $versions;
    }

    public function markdownsExtra ($markdowns=array()) {
        $ms = array ();
        $is_editable = SWEF_BOOL_TRUE;
        foreach ($markdowns as $m) {
            $m[swefcms_col_is_live] = SWEF_BOOL_FALSE;
            if ($m[swefcms_col_published]) {
                if ($is_editable) {
                    // Highest published version
                    $m[swefcms_col_is_live] = SWEF_BOOL_TRUE;
                }
                // All versions lower than the live version are uneditable
                $is_editable = false;
            }
            $m[swefcms_col_is_editable] = $is_editable;
            array_push ($ms,$m);
        }
        return $ms;
    }

    public static function slugify ($item,$spacer=swefcms_slug_spacer,$sep=swefcms_slug_dir_separator) {
        $str      = SWEF_STR__EMPTY;
        if (!$item[swefcms_col_item_uuid]) {
            return $str;
        }
        if ($item[swefcms_col_mother_uuid]) {
            $str .= \Swef\SwefCMS::slugifyString ($item[swefcms_col_mother][swefcms_col_markdowns][0][swefcms_col_title],$spacer);
            $str .= $sep;
        }
        $str     .= \Swef\SwefCMS::slugifyString ($item[swefcms_col_markdowns][0][swefcms_col_title],$spacer);
        $str     .= $sep;
        $str     .= $item[swefcms_col_item_uuid];
        return $str;
    }

    public static function slugifyString ($str,$spacer) {
        foreach (swefcms_slug_convert_chars as $from=>$to) {
            $str    = str_replace ($from,$to,$str);
        }
        if (swefcms_charset!=swefcms_slug_utf8) {
            // Converting (for example) latin1 directly to ASCII causes strange output
            $str    = iconv (swefcms_charset,swefcms_slug_utf8,$str);
        }
        $str        = iconv (swefcms_slug_utf8,swefcms_slug_ascii_translit,$str);
        $str        = strtolower ($str);
        $str        = preg_replace (swefcms_slug_strip_preg,SWEF_STR__SPACE,$str);
        while (strpos($str,SWEF_STR__SPACE.SWEF_STR__SPACE)!==SWEF_BOOL_FALSE) {
            $str    = str_replace (SWEF_STR__SPACE.SWEF_STR__SPACE,SWEF_STR__SPACE,$str);
        }
        $str        = str_replace (SWEF_STR__SPACE,$spacer,trim($str));
        return $str;
    }

}


?>
