
-- PROCEDURES --

DELIMITER $$

DROP PROCEDURE IF EXISTS `swefCMSCheckOut`$$
CREATE PROCEDURE `swefCMSCheckOut`(IN `itm` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii, IN `usr` VARCHAR(255) CHARSET ascii)
BEGIN
  UPDATE `swefcms_language` SET
    `language_Checked_Out_By_UUID`=usr
    WHERE `language_Item_UUID`=itm
      AND `language_Language`=lng
      AND `language_Checked_Out_By_UUID`='';
  SELECT `language_Checked_Out_By_UUID` AS `editor_uuid`
    FROM `swefcms_language`
    WHERE `language_Item_UUID`=itm
      AND `language_Language`=lng
      AND `language_Checked_Out_By_UUID`=usr
    LIMIT 0,1;
END$$

DROP PROCEDURE IF EXISTS `swefCMSChildren`$$
CREATE PROCEDURE `swefCMSChildren`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii)
BEGIN
  SELECT `item_UUID` AS `item_uuid`
        ,`item_Active` AS `active`
        ,`item_Order` AS `order`
        ,`m`.`markdown_Language` AS `language`
        ,`m`.`markdown_Version` AS `version`
        ,`m`.`markdown_Title` AS `title`
        ,`item_Created` AS `created`
        ,`c`.`user_UUID` AS `creator_uuid`
        ,`c`.`user_Name_Display` AS `creator`
        ,`item_Updated` AS `updated`
        ,`u`.`user_UUID` AS `updater_uuid`
        ,`u`.`user_Name_Display` AS `updater`
        ,`co`.`user_UUID` AS `editor_uuid`
        ,`co`.`user_Name_Display` AS `editor`
        ,(`collection_Item_UUID` IS NOT NULL) AS `is_collection`
  FROM `swefcms_markdown` AS `m`
  LEFT JOIN `swefcms_language`
         ON `language_Item_UUID`=`markdown_Item_UUID`
        AND `language_Language`=`markdown_Language`
  LEFT JOIN `swefcms_item`
         ON `item_UUID`=`language_Item_UUID`
  INNER JOIN (
      SELECT `markdown_Item_UUID`
            ,MAX(`markdown_Version`) AS `current`
      FROM `swefcms_markdown`
      WHERE `markdown_Published`='1'
      GROUP BY `markdown_Item_UUID`,`markdown_Language`
      ORDER BY (`markdown_Language` LIKE lng) DESC
              ,(
                     lng LIKE CONCAT(`markdown_Language`,'%')
                  OR `markdown_Language` LIKE CONCAT(lng,'%')
               ) DESC
              ,(lng LIKE CONCAT(`markdown_Language`,'%')) DESC
              ,(`markdown_Language` LIKE CONCAT(lng,'%')) DESC
              ,`markdown_Language` ASC
              ,`markdown_Version` DESC
    ) AS `m2`
        ON `m2`.`markdown_Item_UUID`=`m`.`markdown_Item_UUID`
       AND `m2`.`current`=`m`.`markdown_Version`
  LEFT JOIN `swefcms_collection`
         ON `collection_Item_UUID`=`item_UUID`
  LEFT JOIN `swef_user` AS `c`
         ON `c`.`user_UUID`=`item_Created_By_UUID`
  LEFT JOIN `swef_user` AS `u`
         ON `u`.`user_UUID`=`item_Updated_By_UUID`
  LEFT JOIN `swef_user` AS `co`
         ON `co`.`user_UUID`=`language_Checked_Out_By_UUID`
  WHERE `item_Mother_UUID`=uui
    AND `item_UUID`!=''
  GROUP BY `item_UUID`
  ORDER BY `item_Order`;
END$$

DROP PROCEDURE IF EXISTS `swefCMSCollection`$$
CREATE PROCEDURE `swefCMSCollection`(IN `uui` VARCHAR(255) CHARSET ascii)
BEGIN
  SELECT `collection_Item_UUID` AS `uuid`
        ,`collection_Context` AS `context`
        ,`collection_Usergroup` AS `usergroup`
        ,`usergroup_Name_Display` AS `usergroup_name`
        ,`collection_Template` AS `template`
        ,`collection_Create_Item` AS `may_create`
        ,`collection_Update_Item` AS `may_update`
        ,`collection_Delete_Item` AS `may_delete`
  FROM `swefcms_collection`
  LEFT JOIN `swef_config_usergroup`
         ON `usergroup_Usergroup`=`collection_Usergroup`
  LEFT JOIN `swefcms_item`
         ON `item_UUID`=`collection_Item_UUID`
  WHERE `collection_Item_UUID`=uui;
END$$

DROP PROCEDURE IF EXISTS `swefCMSCollectionNew`$$
CREATE PROCEDURE `swefCMSCollectionNew`(IN `uui` VARCHAR(255) CHARSET ascii, IN `ctx` VARCHAR(64) CHARSET ascii, IN `ugp` VARCHAR(64) CHARSET ascii)
BEGIN
  INSERT INTO `swefcms_collection`
  SET `collection_Item_UUID`=uui
     ,`collection_Context`=ctx
     ,`collection_Usergroup`=ugp;
END$$

DROP PROCEDURE IF EXISTS `swefCMSCollections`$$
CREATE PROCEDURE `swefCMSCollections`(IN `lng` VARCHAR(64) CHARSET ascii)
BEGIN
  SELECT `item_UUID` AS `item_uuid`
        ,`cl`.`collection_Context` AS `context`
        ,`cl`.`collection_Usergroup` AS `usergroup`
        ,`cl`.`collection_Template` AS `template`
        ,(    `item_UUID`!=''
          AND `all`.`collection_Create_Item`
         ) AS `may_grant`
        ,`cl`.`collection_Create_Item` AS `may_create`
        ,`cl`.`collection_Update_Item` AS `may_update`
        ,`cl`.`collection_Delete_Item` AS `may_delete`
        ,`item_Active` AS `active`
        ,`item_Created` AS `created`
        ,`c`.`user_UUID` AS `creator_uuid`
        ,`c`.`user_Name_Display` AS `creator`
        ,`item_Updated` AS `updated`
        ,`u`.`user_UUID` AS `updater_uuid`
        ,`u`.`user_Name_Display` AS `updater`
        ,`co`.`user_UUID` AS `editor_uuid`
        ,`co`.`user_Name_Display` AS `editor`
        ,GROUP_CONCAT(`markdown`.`markdown_Language` ORDER BY `markdown_Language` SEPARATOR ',') AS `languages`
        ,`markdown`.`markdown_Title` AS `title`
        ,`markdown`.`markdown_Language` AS `language`
        ,`markdown`.`markdown_Version` AS `version`
        ,`markdown`.`markdown_Published` AS `published`
  FROM `swefcms_collection` AS `cl`
  LEFT JOIN `swefcms_collection` AS `all`
         ON `all`.`collection_Item_UUID`=''
        AND `all`.`collection_Usergroup`=`cl`.`collection_Usergroup`
  LEFT JOIN `swefcms_item`
         ON `item_UUID`=`cl`.`collection_Item_UUID`
  LEFT JOIN (
              SELECT `m`.`markdown_Title`
                    ,`m`.`markdown_Language`
                    ,`m`.`markdown_Version`
                    ,`m`.`markdown_Published`
                    ,`m`.`markdown_item_UUID`
                    ,`l`.`language_Checked_Out_By_UUID`
              FROM `swefcms_markdown` AS `m`
              LEFT JOIN `swefcms_language` AS `l`
                     ON `l`.`language_Item_UUID`=`m`.`markdown_Item_UUID`
                    AND `l`.`language_Language`=`m`.`markdown_Language`
              LEFT JOIN `swefcms_markdown` AS `newer`
                     ON `newer`.`markdown_Item_UUID`=`m`.`markdown_Item_UUID`
                    AND `newer`.`markdown_Language`=`m`.`markdown_Language`
                    AND `newer`.`markdown_Version`>`m`.`markdown_Version`
              WHERE `newer`.`markdown_Item_UUID` IS NULL
              ORDER BY (`m`.`markdown_Language` LIKE lng) DESC
                  ,(
                        lng LIKE CONCAT(`m`.`markdown_Language`,'%')
                     OR `m`.`markdown_Language` LIKE CONCAT(lng,'%')
                   ) DESC
                  ,(lng LIKE CONCAT(`m`.`markdown_Language`,'%')) DESC
                  ,(`m`.`markdown_Language` LIKE CONCAT(lng,'%')) DESC
                  ,`m`.`markdown_Language` ASC
            ) AS `markdown` ON  `markdown`.`markdown_item_UUID`=`item_UUID`
  LEFT JOIN `swef_user` AS `c`
         ON `c`.`user_UUID`=`item_Created_By_UUID`
  LEFT JOIN `swef_user` AS `u`
         ON `u`.`user_UUID`=`item_Updated_By_UUID`
  LEFT JOIN `swef_user` AS `co`
         ON `co`.`user_UUID`=`language_Checked_Out_By_UUID`
GROUP BY `cl`.`collection_Item_UUID`,`cl`.`collection_Context`,`cl`.`collection_Usergroup`
ORDER BY `item_uuid`!='',`title`;
END$$

DROP PROCEDURE IF EXISTS `swefCMSItem`$$
CREATE PROCEDURE `swefCMSItem`(IN `uui` VARCHAR(255) CHARSET ascii)
BEGIN
  SELECT `mother`.`item_UUID` AS `mother_uuid`
        ,`item`.`item_UUID` AS `item_uuid`
        ,`item`.`item_Active` AS `active`
        ,`item`.`item_Order` AS `order`
        ,`item`.`item_Created` AS `created`
        ,`c`.`user_UUID` AS `creator_uuid`
        ,`c`.`user_Name_Display` AS `creator`
        ,`item`.`item_Updated` AS `updated`
        ,`u`.`user_UUID` AS `updater_uuid`
        ,`u`.`user_Name_Display` AS `updater`
        ,(`collection_Item_UUID` IS NOT NULL) AS `is_collection`
        ,GROUP_CONCAT(
            DISTINCT `language_Language`
            ORDER BY `language_Language`
            ASC SEPARATOR ','
         ) AS `languages`
  FROM `swefcms_item` AS `item`
  LEFT JOIN `swefcms_item` AS `mother`
         ON `mother`.`item_UUID`=`item`.`item_Mother_UUID`
  LEFT JOIN `swefcms_collection`
         ON `collection_Item_UUID`=`item`.`item_UUID`
  LEFT JOIN `swef_user` AS `c`
         ON `c`.`user_UUID`=`item`.`item_Created_By_UUID`
  LEFT JOIN `swef_user` AS `u`
         ON `u`.`user_UUID`=`item`.`item_Updated_By_UUID`
  LEFT JOIN `swefcms_language`
         ON `language_Item_UUID`=`item`.`item_UUID`
  WHERE `item`.`item_UUID`=uui
  GROUP BY `item_UUID`
  LIMIT 0,1;
END$$

DROP PROCEDURE IF EXISTS `swefCMSItemNew`$$
CREATE PROCEDURE `swefCMSItemNew`(IN `uui` VARCHAR(255) CHARSET ascii, IN `uid` VARCHAR(255) CHARSET ascii, IN `dt` VARCHAR(32) CHARSET ascii)
BEGIN
  INSERT INTO `swefcms_item`
  SET `item_UUID`=uui
     ,`item_Created`=dt
     ,`item_Created_By_UUID`=uid
     ,`item_Updated`=dt
     ,`item_Updated_By_UUID`=uid;
END$$

DROP PROCEDURE IF EXISTS `swefCMSItemProperties`$$
CREATE PROCEDURE `swefCMSItemProperties`(IN `uui` VARCHAR(255) CHARSET ascii)
BEGIN
  SELECT `item_Mother_UUID` AS `mother_uuid`
        ,`item_UUID` AS `item_uuid`
        ,`item_Active` AS `active`
        ,`item_Order` AS `order`
        ,`item_Created` AS `created`
        ,`item_Created_By_UUID` AS `creator`
        ,`item_Updated` AS `updated`
        ,`item_Updated_By_UUID` AS `updater`
  FROM `swefcms_item`
  WHERE `item_UUID`=uui
  LIMIT 0,1;
END$$

DROP PROCEDURE IF EXISTS `swefCMSItemUpdate`$$
CREATE PROCEDURE `swefCMSItemUpdate`(IN `uui` VARCHAR(255) CHARSET ascii, IN `acv` INT(1) UNSIGNED, IN `ord` INT(1) UNSIGNED, IN `upr` VARCHAR(255) CHARSET ascii, IN `upd` VARCHAR(32) CHARSET ascii)
BEGIN
  UPDATE `swefcms_item` SET
    `item_Active`=acv
   ,`item_Order`=ord
   ,`item_Updated_By_UUID`=upr
   ,`item_Updated`=upd
  WHERE `item_UUID`=uui;
END$$

DROP PROCEDURE IF EXISTS `swefCMSLanguageNew`$$
CREATE PROCEDURE `swefCMSLanguageNew`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii)
BEGIN
  INSERT INTO `swefcms_language`
  SET `language_Item_UUID`=uui
     ,`language_Language`=lng;
END$$

DROP PROCEDURE IF EXISTS `swefCMSMarkdown`$$
CREATE PROCEDURE `swefCMSMarkdown`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii)
BEGIN
  SELECT `markdown_Item_UUID` AS `item_uuid`
        ,`markdown_Language` AS `language`
        ,`markdown_Version` AS `version`
        ,`markdown_Published` AS `published`
        ,`markdown_Title` AS `title`
        ,`markdown_Created` AS `created`
        ,`c`.`user_UUID` AS `creator_uuid`
        ,`c`.`user_Name_Display` AS `creator`
        ,`markdown_Updated` AS `updated`
        ,`u`.`user_UUID` AS `updater_uuid`
        ,`u`.`user_Name_Display` AS `updater`
        ,`co`.`user_UUID` AS `editor_uuid`
        ,`co`.`user_Name_Display` AS `editor`
        ,`markdown_Update_Etag_UUID` AS `etag`
  FROM `swefcms_markdown`
  LEFT JOIN `swef_user` AS `c`
         ON `c`.`user_UUID`=`markdown_Created_By_UUID`
  LEFT JOIN `swef_user` AS `u`
         ON `u`.`user_UUID`=`markdown_Updated_By_UUID`
  LEFT JOIN `swefcms_language`
         ON `language_Item_UUID`=`markdown_Item_UUID`
        AND `language_Language`=`markdown_Language`
  LEFT JOIN `swef_user` AS `co`
         ON `co`.`user_UUID`=`language_Checked_Out_By_UUID`
  WHERE `markdown_Item_UUID`=uui
    AND `markdown_Language`=lng
  ORDER BY `markdown_Version` DESC;
END$$

DROP PROCEDURE IF EXISTS `swefCMSMarkdownNew`$$
CREATE PROCEDURE `swefCMSMarkdownNew`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii, IN `v` INT(11) UNSIGNED, IN `ttl` VARCHAR(255) CHARSET utf8, IN `dt` VARCHAR(32) CHARSET ascii, IN `uid` VARCHAR(255) CHARSET ascii, IN `etag` VARCHAR(255) CHARSET ascii)
BEGIN
  INSERT INTO `swefcms_markdown`
  SET `markdown_Item_UUID`=uui
     ,`markdown_Language`=lng
     ,`markdown_Version`=v
     ,`markdown_Title`=ttl
     ,`markdown_Created`=dt
     ,`markdown_Created_By_UUID`=uid
     ,`markdown_Updated`=dt
     ,`markdown_Updated_By_UUID`=uid
     ,`markdown_Updated_Etag_UUID`=etag;
END$$

DROP PROCEDURE IF EXISTS `swefCMSMarkdowns`$$
CREATE PROCEDURE `swefCMSMarkdowns`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii)
BEGIN
  SELECT `m`.`markdown_Item_UUID` AS `item_uuid`
        ,`m`.`markdown_Language` AS `language`
        ,`m`.`markdown_Version` AS `version`
        ,`m`.`markdown_Published` AS `published`
        ,`m`.`markdown_Title` AS `title`
        ,`m`.`markdown_Created` AS `created`
        ,`c`.`user_UUID` AS `creator_uuid`
        ,`c`.`user_Name_Display` AS `creator`
        ,`m`.`markdown_Updated` AS `updated`
        ,`u`.`user_UUID` AS `updater_uuid`
        ,`u`.`user_Name_Display` AS `updater`
        ,`co`.`user_UUID` AS `editor_uuid`
        ,`co`.`user_Name_Display` AS `editor`
        ,`m`.`markdown_Update_Etag_UUID` AS `etag`
        ,(`m`.`markdown_Language`=lng) AS `lang_match`
        ,(lng LIKE CONCAT(`m`.`markdown_Language`,'%')) AS `lang_is_superset`
        ,(`m`.`markdown_Language` LIKE CONCAT(lng,'%')) AS `lang_is_subset`
  FROM `swefcms_markdown` AS `m`
  LEFT JOIN `swefcms_markdown` AS `newer`
         ON `newer`.`markdown_Item_UUID`=`m`.`markdown_Item_UUID`
        AND `newer`.`markdown_Language`=`m`.`markdown_Language`
        AND `newer`.`markdown_Version`>`m`.`markdown_Version`
  LEFT JOIN `swef_user` AS `c`
         ON `c`.`user_UUID`=`m`.`markdown_Created_By_UUID`
  LEFT JOIN `swef_user` AS `u`
         ON `u`.`user_UUID`=`m`.`markdown_Updated_By_UUID`
  LEFT JOIN `swefcms_language`
         ON `language_Item_UUID`=`m`.`markdown_Item_UUID`
        AND `language_Language`=`m`.`markdown_Language`
  LEFT JOIN `swef_user` AS `co`
         ON `co`.`user_UUID`=`language_Checked_Out_By_UUID`
  WHERE `newer`.`markdown_Item_UUID` IS NULL
    AND `m`.`markdown_Item_UUID`=uui
  ORDER BY `lang_match` DESC,`lang_is_superset` DESC,`lang_is_subset` DESC,`m`.`markdown_Version` DESC;
END$$

DROP PROCEDURE IF EXISTS `swefCMSMarkdownSource`$$
CREATE PROCEDURE `swefCMSMarkdownSource`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii, IN `v` INT(11) UNSIGNED)
BEGIN
  SELECT `language_Checked_Out_By_UUID` AS `editor_uuid`
        ,`markdown_Title` AS `title`
        ,`markdown_Markdown` AS `markdown_source`
  FROM `swefcms_markdown`
  LEFT JOIN `swefcms_language`
         ON `language_Item_UUID`=`markdown_Item_UUID`
        AND `language_Language`=`markdown_Language`
  WHERE `markdown_Item_UUID`=uui
    AND `markdown_Language`=lng
    AND `markdown_Version`=v
  LIMIT 0,1;
END$$

DROP PROCEDURE IF EXISTS `swefCMSRelationAdd`$$
CREATE PROCEDURE `swefCMSRelationAdd`(IN `iid` VARCHAR(255) CHARSET ascii, IN `rid` VARCHAR(255) CHARSET ascii)
BEGIN
INSERT INTO `swefcms_relation` (
    `relation_Lower_Item_UUID`,`relation_Higher_Item_UUID`
)
    SELECT IF(iid=rid,NULL,IF(iid<rid,iid,rid))
          ,IF(iid=rid,NULL,IF(iid<rid,rid,iid))
;
END$$

DROP PROCEDURE IF EXISTS `swefCMSRelationRemove`$$
CREATE PROCEDURE `swefCMSRelationRemove`(IN `iid` VARCHAR(255) CHARSET ascii, IN `rid` VARCHAR(255) CHARSET ascii)
BEGIN
DELETE FROM `swefcms_relation`
    WHERE ( `relation_Lower_Item_UUID`=iid AND `relation_Higher_Item_UUID`=rid )
       OR ( `relation_Lower_Item_UUID`=rid AND `relation_Higher_Item_UUID`=iid )
;
END$$

DROP PROCEDURE IF EXISTS `swefCMSRelations`$$
CREATE PROCEDURE `swefCMSRelations`(IN `uui` VARCHAR(255) CHARSET ascii, IN `lng` VARCHAR(64) CHARSET ascii)
BEGIN
  SELECT `item_UUID` AS `item_uuid`
        ,`item_Active` AS `active`
        ,`item_Order` AS `order`
        ,`markdown_Language` AS `language`
        ,`markdown_Version` AS `version`
        ,`markdown_Published` AS `published`
        ,`markdown_Title` AS `title`
        ,`item_Created` AS `created`
        ,`c`.`user_UUID` AS `creator_uuid`
        ,`c`.`user_Name_Display` AS `creator`
        ,`item_Updated` AS `updated`
        ,`u`.`user_UUID` AS `updater_uuid`
        ,`u`.`user_Name_Display` AS `updater`
        ,(`collection_Item_UUID` IS NOT NULL) AS `is_collection`
  FROM `swefcms_markdown` AS `m`
  LEFT JOIN `swefcms_item`
         ON `item_UUID`=`markdown_Item_UUID`
  INNER JOIN `swefcms_relation`
     ON `relation_Lower_Item_UUID`=`item_UUID`
     OR `relation_Higher_Item_UUID`=`item_UUID`
  INNER JOIN (
      SELECT `markdown_Item_UUID`
            ,MAX(`markdown_Version`) AS `current`
      FROM `swefcms_markdown`
      GROUP BY `markdown_Item_UUID`,`markdown_Language`
      ORDER BY (`markdown_Language` LIKE lng) DESC
              ,(
                     lng LIKE CONCAT(`markdown_Language`,'%')
                  OR `markdown_Language` LIKE CONCAT(lng,'%')
               ) DESC
              ,(lng LIKE CONCAT(`markdown_Language`,'%')) DESC
              ,(`markdown_Language` LIKE CONCAT(lng,'%')) DESC
              ,`markdown_Language` ASC
              ,`markdown_Version` DESC
    ) AS `m2`
        ON `m2`.`markdown_Item_UUID`=`m`.`markdown_Item_UUID`
       AND `m2`.`current`=`m`.`markdown_Version`
  LEFT JOIN `swefcms_collection`
         ON `collection_Item_UUID`=`item_UUID`
  LEFT JOIN `swef_user` AS `c`
         ON `c`.`user_UUID`=`item_Created_By_UUID`
  LEFT JOIN `swef_user` AS `u`
         ON `u`.`user_UUID`=`item_Updated_By_UUID`
  WHERE (`item_UUID`=`relation_Lower_Item_UUID` AND `relation_Higher_Item_UUID`=uui)
     OR (`item_UUID`=`relation_Higher_Item_UUID` AND `relation_Lower_Item_UUID`=uui)
  GROUP BY `item_UUID`
  ORDER BY `item_Created`;
END$$

DELIMITER ;


-- SWEF API --

INSERT INTO `swef_config_api`
    ( `api_Procedure`, `api_Context_Preg_Match`, `api_Num_Args`, `api_Usergroup_Preg_Match`, `api_Description` )
  VALUES
    (
      '\\Swef\\SwefCMS::apiItemProperties',
      '<^.*$>', 1, '<^.*$>',
      '\\Swef\\SwefCMS::itemSelect ([item UUID]): Return properties for a CMS item ONLY IF a membership allows the current user in the current context (see swefcms_collection and user->memberships)'
    ),
    (
      '\\Swef\\SwefCMS::apiItemUpdate',
      '<^.*$>', 3, '<^.*$>',
      '\\Swef\\SwefCMS::itemUpdate ([item UUID],[active],[order]): Update properties of a CMS item (permissions handled by calling method)'
    ),
    (
      '\\Swef\\SwefCMS::apiRelationAdd',
      '<^.*$>', 2, '<^.*$>',
      '\\Swef\\SwefCMS::RelationAdd ([item UUID],[relation UUID]): Add a relation to a CMS item (permissions handled by calling method)'
      ),
    (
      '\\Swef\\SwefCMS::apiRelationRemove',
      '<^.*$>', 2, '<^.*$>',
      '\\Swef\\SwefCMS::RelationRemove ([item UUID],[relation UUID]): Remove a relation of a CMS item (permissions handled by calling method)'
    );


-- SWEF INPUT FILTERING --

INSERT IGNORE INTO `swef_config_input`
    ( `input_Procedure`, `input_Arg`, `input_Filter_Name` )
  VALUES
    ( 'swefCMSChildren',        1,  'uuidOrEmpty'       ),
    ( 'swefCMSChildren',        2,  'languageCode'      ),
    ( 'swefCMSCollection',      1,  'uuidOrEmpty'       ),
    ( 'swefCMSCollectionNew',   1,  'uuid'              ),
    ( 'swefCMSCollectionNew',   2,  'context'           ),
    ( 'swefCMSCollectionNew',   3,  'usergroup'         ),
    ( 'swefCMSCollections',     1,  'languageCode'      ),
    ( 'swefCMSItem',            1,  'uuidOrEmpty'       ),
    ( 'swefCMSItemNew',         1,  'uuid'              ),
    ( 'swefCMSItemNew',         2,  'uuid'              ),
    ( 'swefCMSItemNew',         3,  'datetimeISO8601'   ),
    ( 'swefCMSItemProperties',  1,  'uuidOrEmpty'       ),
    ( 'swefCMSItemUpdate',      1,  'uuidOrEmpty'       ),
    ( 'swefCMSItemUpdate',      2,  'int10'             ),
    ( 'swefCMSItemUpdate',      3,  'int10Positive'     ),
    ( 'swefCMSItemUpdate',      4,  'uuid'              ),
    ( 'swefCMSItemUpdate',      5,  'datetimeISO8601'   ),
    ( 'swefCMSLanguageNew',     1,  'uuid'              ),
    ( 'swefCMSLanguageNew',     2,  'languageCode'      ),
    ( 'swefCMSMarkdown',        1,  'uuidOrEmpty'       ),
    ( 'swefCMSMarkdown',        2,  'languageCode'      ),
    ( 'swefCMSMarkdownNew',     1,  'uuid'              ),
    ( 'swefCMSMarkdownNew',     2,  'languageCode'      ),
    ( 'swefCMSMarkdownNew',     3,  'int10Positive'     ),
    ( 'swefCMSMarkdownNew',     4,  'string1-255'       ),
    ( 'swefCMSMarkdownNew',     5,  'datetimeISO8601'   ),
    ( 'swefCMSMarkdownNew',     6,  'uuid'              ),
    ( 'swefCMSMarkdownNew',     7,  'uuid'              ),
    ( 'swefCMSMarkdowns',       1,  'uuidOrEmpty'       ),
    ( 'swefCMSMarkdowns',       2,  'languageCode'      ),
    ( 'swefCMSMarkdownSource',  1,  'uuidOrEmpty'       ),
    ( 'swefCMSMarkdownSource',  2,  'languageCode'      ),
    ( 'swefCMSMarkdownSource',  3,  'int10'             ),
    ( 'swefCMSRelations',       1,  'uuidOrEmpty'       ),
    ( 'swefCMSRelations',       2,  'languageCode'      );


-- SWEF PLUGIN REGISTRATION --

INSERT IGNORE INTO `swef_config_plugin`
    (
      `plugin_Dash_Allow`, `plugin_Dash_Usergroup_Preg_Match`, `plugin_Enabled`,
      `plugin_Context_LIKE`, `plugin_Classname`, `plugin_Handle_Priority`
    )
  VALUES
    ( 1, '<^sysadmin$>', 1, 'dashboard', '\\Swef\\SwefCMS', 100 ),
    ( 0, '', 1, 'www-%', '\\Swef\\SwefCMS', 100 );


-- SWEFCMS TABLES --

CREATE TABLE `swefcms_collection` (
  `collection_Item_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `collection_Context` varchar(64) CHARACTER SET ascii NOT NULL,
  `collection_Usergroup` varchar(64) CHARACTER SET ascii NOT NULL,
  `collection_Template` varchar(255) CHARACTER SET ascii NOT NULL,
  `collection_Create_Item` int(1) unsigned NOT NULL,
  `collection_Update_Item` int(1) unsigned NOT NULL,
  `collection_Delete_Item` int(11) NOT NULL,
  PRIMARY KEY (`collection_Item_UUID`,`collection_Context`,`collection_Usergroup`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `swefcms_collection` (`collection_Item_UUID`, `collection_Context`, `collection_Usergroup`, `collection_Template`, `collection_Create_Item`, `collection_Update_Item`, `collection_Delete_Item`) VALUES
('',  'dashboard',  'admin',  'html/dashboard.default.html',  1,  0,  0),
('',  'dashboard',  'sysadmin', 'html/dashboard.default.html',  1,  0,  0),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'dashboard',  'admin',  'html/dashboard.default.html',  0,  0,  0),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'dashboard',  'sysadmin', 'html/dashboard.default.html',  1,  1,  1),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'www-en', 'anon', 'html/dashboard.default.html',  0,  0,  0),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'www-en', 'www',  'html/dashboard.default.html',  0,  0,  0),
('0a71b5b1-c79a-11e7-9428-d8d3859a9e13',  'dashboard',  'admin',  'html/dashboard.default.html',  1,  1,  1),
('0a71b5b1-c79a-11e7-9428-d8d3859a9e13',  'dashboard',  'sysadmin', 'html/dashboard.default.html',  0,  1,  0);

CREATE TABLE `swefcms_item` (
  `item_Mother_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `item_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `item_Active` int(1) unsigned NOT NULL,
  `item_Order` int(11) unsigned NOT NULL,
  `item_Created` varchar(32) CHARACTER SET ascii NOT NULL,
  `item_Created_By_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `item_Updated` varchar(32) CHARACTER SET ascii NOT NULL,
  `item_Updated_By_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`item_UUID`),
  KEY `item_Mother_UUID` (`item_Mother_UUID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `swefcms_item` (`item_Mother_UUID`, `item_UUID`, `item_Active`, `item_Order`, `item_Created`, `item_Created_By_UUID`, `item_Updated`, `item_Updated_By_UUID`) VALUES
('',  '', 1,  0,  '2017-11-18T19:00:00+00:00',  '', '2017-11-18T19:00:00+00:00',  ''),
('',  '0a6e22e9-c79a-11e7-9428-d8d3859a9e13', 1,  0,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-12-24T13:37:59+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  '0a719714-c79a-11e7-9428-d8d3859a9e13', 1,  0,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-12-27T23:06:24+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  '0a719c0a-c79a-11e7-9428-d8d3859a9e13', 1,  1,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2018-01-05T19:45:37+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  '0a719f5d-c79a-11e7-9428-d8d3859a9e13', 0,  2,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2018-01-02T12:29:02+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  '0a71a3a2-c79a-11e7-9428-d8d3859a9e13', 1,  2,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  '0a71a840-c79a-11e7-9428-d8d3859a9e13', 1,  1,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  '0a71ae7d-c79a-11e7-9428-d8d3859a9e13', 1,  0,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  '0a71b219-c79a-11e7-9428-d8d3859a9e13', 1,  3,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('',  '0a71b5b1-c79a-11e7-9428-d8d3859a9e13', 1,  0,  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13'),
('0a71b5b1-c79a-11e7-9428-d8d3859a9e13',  '0a71b8ca-c79a-11e7-9428-d8d3859a9e13', 1,  0,  '2017-10-25T09:39:14+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-25T09:39:14+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13');

CREATE TABLE `swefcms_language` (
  `language_Item_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `language_Language` varchar(64) CHARACTER SET ascii NOT NULL,
  `language_Checked_Out_By_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`language_Item_UUID`,`language_Language`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `swefcms_language` (`language_Item_UUID`, `language_Language`, `language_Checked_Out_By_UUID`) VALUES
('',  'en-gb',  ''),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'fr', ''),
('0a719714-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a719c0a-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a71a3a2-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a71a840-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a71ae7d-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a71b219-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a71b5b1-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  ''),
('0a71b8ca-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13');

CREATE TABLE `swefcms_markdown` (
  `markdown_Item_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `markdown_Language` varchar(64) CHARACTER SET ascii NOT NULL,
  `markdown_Version` int(11) unsigned NOT NULL DEFAULT '1',
  `markdown_Published` int(1) unsigned NOT NULL,
  `markdown_Title` varchar(255) NOT NULL,
  `markdown_Created` varchar(32) CHARACTER SET ascii NOT NULL,
  `markdown_Created_By_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `markdown_Updated` varchar(32) CHARACTER SET ascii NOT NULL,
  `markdown_Updated_By_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `markdown_Update_Etag_UUID` varchar(64) CHARACTER SET ascii NOT NULL,
  `markdown_Markdown` text NOT NULL,
  PRIMARY KEY (`markdown_Item_UUID`,`markdown_Language`,`markdown_Version`),
  UNIQUE KEY `markdown_Update_Etag_UUID` (`markdown_Update_Etag_UUID`),
  KEY `markdown_Updated_By_UUID` (`markdown_Updated_By_UUID`),
  KEY `markdown_Created_By_UUID` (`markdown_Created_By_UUID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `swefcms_markdown` (`markdown_Item_UUID`, `markdown_Language`, `markdown_Version`, `markdown_Published`, `markdown_Title`, `markdown_Created`, `markdown_Created_By_UUID`, `markdown_Updated`, `markdown_Updated_By_UUID`, `markdown_Update_Etag_UUID`, `markdown_Markdown`) VALUES
('',  'en-gb',  1,  1,  'All Collections',  '2017-11-18T19:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-11-18T19:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '0a658b11-cc81-11e7-9036-d8d3859a9e13', ''),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'SWEF Technical Manual',  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d69a4ee-cc7f-11e7-9036-d8d3859a9e13', 'Welcome to the SWEF technical manual!'),
('0a6e22e9-c79a-11e7-9428-d8d3859a9e13',  'fr', 1,  1,  'Manuel Technique pour SWEF', '2017-12-09T15:43:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-12-09T15:43:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', 'c587447a-dcf7-11e7-8de6-d8d3859a9e13', 'Bonjour!'),
('0a719714-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Features', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b65f4-cc7f-11e7-9036-d8d3859a9e13', 'SWEF has a some really cool features.'),
('0a719c0a-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Introduction', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6737-cc7f-11e7-9036-d8d3859a9e13', 'SWEF is a web application framework with lots of features.'),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Key Principals', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b683d-cc7f-11e7-9036-d8d3859a9e13', 'These are the key principles of SWEF.'),
('0a71a3a2-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Components', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6937-cc7f-11e7-9036-d8d3859a9e13', 'A component is an atomic unit of web script (eg. ./app/script/some.name.php).\r\n\r\nAll components (even if not pages) may be pushed with the appropriate request URI  (eg. ./some.name) and they may all be pulled by a template.'),
('0a71a840-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Contexts', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6a5c-cc7f-11e7-9036-d8d3859a9e13', 'The most fundamental logical separation in the SWEF philosophy is context.\r\n\r\nContext is defined in the look-up table swef_context and provides HTTP access to the system. New contexts may be added but these are provided:\r\n * Dashboard - \'dashboard\'\r\n * Public webiste - \'www\'\r\n * JSON API - \'json\'\r\n\r\nSWEF deploys PHP function preg_match to match the value held in a $_SERVER environment variable to a context.\r\n\r\nThe default is to match on SERVER_NAME. Using other approaches may have impacts on ./.htaccess\r\n\r\nExamples:\r\n * Match on SERVER_NAME:\r\n    * dashboard.my.domain\r\n    * www.my.domain\r\n    * json.my.domain\r\n * Match on REQUEST_URI\r\n    * www.my.domain/dashboard\r\n    * www.my.domain\r\n    * www.my.domain/json\r\n * Match on SERVER_PORT\r\n    * www.my.domain:123\r\n    * www.my.domain:443\r\n    * www.my.domain:789\r\n   \r\n\r\n'),
('0a71ae7d-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'HTTP Requests',  '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6c48-cc7f-11e7-9036-d8d3859a9e13', 'SWEF interprets native requests like this:\r\n\r\n./some_script => ./app/script/some_script.php\r\n\r\nSWEF also deploys slugs (store in table swef_slug) that map friendly request URIs to native component request URIs.\r\n\r\nFor example:\r\n\r\n./my-script-option-1 => ./some.name?option=1\r\n\r\nSlugs are also deployed by native (and possibly other) plugins. These native plugins are examples:\r\n * swefError  reacts to ./403 and ./404\r\n * swefLogin reacts to ./login and ./logout\r\n * swefCMS reacts to slugs where they match its page slugs'),
('0a71b219-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Routers and usergroup access', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6d78-cc7f-11e7-9036-d8d3859a9e13', 'Using the look-up database table swef_router, SWEF uses PHP function preg_match() to match regular expressions for components and usergroupss to contexts (which also have the simple wildcard value *).\r\n\r\nThese matches are known as routers; if no valid router is found, SWEF will not process the component script.\r\n\r\nThis logic applies to all components including pages.'),
('0a71b5b1-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'SwefCMS Manual', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-24T22:00:00+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6e8a-cc7f-11e7-9036-d8d3859a9e13', 'This is the manual for swefCMS\r\n\r\n'),
('0a71b8ca-c79a-11e7-9428-d8d3859a9e13',  'en-gb',  1,  1,  'Markdown Tutorial',  '2017-10-25T09:39:14+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '2017-10-25T09:39:14+00:00',  'fa5b03f7-c3f1-11e7-beba-d8d3859a9e13', '4d6b6f8c-cc7f-11e7-9036-d8d3859a9e13', '# swefCMS markdown standard\r\n  =========================\r\n\r\n@section-1\r\n## HTML\r\n\r\nHTML is simply passed through **provided that** it is well-formed! /\r\n**Warning:** badly formed HTML will probably cause woes - the markdown parser does not attempt to understand missing/broken tags!\r\n\r\nHTML special characters outside of HTML tags are not parsed but wide spacing may be achieved with underscores separated by white space like this _ **widely _ spaced _ text**.\r\n\r\n<div>\r\n  <cite>Mark Page, 2017 Nov 24th</cite>\r\n</div>\r\n\r\n<div>\r\n  <q>In this house we obey the Laws OF THERMODYNAMICS!</q>\r\n  <cite>Homer Simpson</cite>\r\n</div>\r\n\r\n<p><small>Modify swefcms.[context].css to restyle the resulting HTML markup using the available classes (use the source code view).</small></p>\r\n\r\n@section-2\r\n## Text\r\n\r\n### Paragraphs\r\n\r\nParagraphs are blocks of text separated by at least one empty line. Things like [link](./some.link)s, images, etc. (more details below) may be used inline.\r\n\r\nIt you have no empty line you just get a space.\r\n(This is normal HTML behaviour.)\r\n\r\n### Line breaks\r\n\r\nSo force a line break like \\\r\nthis. You can also do it like /\r\nthis.\r\n\r\n### Emphasised and strong text\r\n\r\nBoth *emphasis* and **strong** are supported.\r\n\r\n### Headings\r\n\r\nUse # at the BEGINNING of a line so not:\r\n\r\n #   Heading\r\n\r\nBut rather:\r\n\r\n#       Heading 1\r\n##       Heading 2\r\n###       Heading 3\r\n####       Heading 4\r\n#####       Heading 5\r\n######       Heading 6\r\n\r\nUnderlining can be used instead (or as well) for <*h1*> and <*h2*>.\r\n\r\nHeading 1\r\n=========\r\n## Heading 2\r\n    ---------\r\n###  Heading 3\r\n####   Heading 4\r\n#####    Heading 5\r\n######     Heading 6\r\n\r\nAnd lazily:\r\n\r\nHeading 1\r\n=\r\n Heading 2\r\n -\r\n\r\n### Horizontal rules\r\n\r\nThese must be preceded by an empty line:\r\n\r\n=\r\n\r\n========\r\n\r\n-\r\n\r\nIf not you get weird behaviour\r\n--------\r\n=\r\n========\r\n-\r\n--------\r\n\r\n### Tabs (labels):\r\n\r\nLabel 1:   : Value 1\r\nLabel 2:   : Value 2\r\nLabel 12345       :: Value 123\r\nLabel 23456:      :: Value 234\r\nVerbose label needs much more space to fit  :::::: Value 345\r\nAnother verbose label                       :::::: Value 345\r\n                                            :::::: Empty label\r\n\r\n\r\n\r\n\r\n@section-3\r\n## Lists\r\n\r\n### Unordered list:\r\n* Item 1\r\n* Item 2\r\n\r\n### Ordered list:\r\n1. Item 1\r\n2. Item 2\r\n\r\n### Nested lists:\r\n* Item A\r\n  1. Item A1\r\n  2. Item A2\r\n* Item B\r\n\r\n### Either way around:\r\n1. Item A\r\n  * Item A1\r\n  * Item A2\r\n2. Item B\r\n\r\n\r\n\r\n\r\n\r\n@section-4\r\n## Tables\r\n\r\nMinimal:\r\n    { **C1,R1**     |   **C2,R1**   }     **C3,R1**\r\n    }         C1,R2 }         C2,R2 { C3,R2\r\n    |   C1,R3,abc   { C2,R3,abc     |   C3,R3,abc\r\n\r\nFull ASCII view:\r\n     -----------------------------------------------\r\n    { **C1,R1**     |   **C2,R1**   }     **C3,R1** |\r\n    }         C1,R2 }         C2,R2 { C3,R2         |\r\n    |   C1,R3,abc   { C2,R3,abc     |   C3,R3,abc   |\r\n     -----------------------------------------------\r\n\r\n\r\n\r\n\r\n\r\n@section-5\r\n## Links and HTML5 media tags\r\n\r\nThe secret to links and media tags is the use of ( visible references )[ internal references ] making sure there is **no space between ) and [**.\r\n\r\n### Visible references\r\n\r\nUse the link:        :: [ ]\r\nTitle/caption:       :: [ My link ]\r\nTitle and caption:   :: [ My link | My caption ]\r\n\r\nCaptions are used for both accessibility and extra information. They are used as the title attribute in links and as a <*figcaption*> in media <*figure*>s.\r\n\r\n### Internal references\r\n\r\nA link:              :: ( ./my-link ) *(to any type of resource)*\r\nA media tag:         :: ( ./my-source-1.oga | ./my-source-2.mp3 ) *(HTML5-supported files)*\r\n\r\n\r\nAdditional internal reference options:\r\n\r\nCSS class:           :: ( ... | my-custom-class ) *(target tag is dependent on file extension)*\r\nIs a link:           :: ( ... | @ ) *(forces a link instead of a media tag)*\r\nIn a new window:     :: ( ... | @@ )\r\nIn combination:      :: ( ... | my-custom-class | @ )\r\n                     :: ( ... | my-custom-class | @@ )\r\n\r\n### Within this document\r\n\r\n@my-section\r\nAnchor (which you can\'t see)\r\n\r\nLink to anchor:      :: [ My section ](  #my-section  )\r\n\r\n                     :: [ Section 1  ](  #section-1   )\r\n\r\n### Linking page or other media\r\n\r\nImage link:          :: [ My cat     ](  ./media/image/eg.png | eg-link-class | @  )\r\n\r\nAudio link:          :: [ New song   ](  ./media/audio/eg.oga | eg-link-class | @  )\r\n\r\nVideo link:          :: [ A video    ](  ./media/video/eg.ogv | eg-link-class | @  )\r\n\r\nWeb page/other:      :: [ Buy now    ](  ./my-shop-home-page  | eg-link-class      )\r\n\r\n                     :: [ Download   ](  http://download.site/anything.pdf | eg-link-class  )\r\n\r\n                     :: [ Read this  ](  http://some.site/anything.pdf     | eg-link-class  )\r\n\r\n### Or targeting a new window\r\n\r\nImage link:          :: [My cat      ](  ./media/image/eg.png | eg-link-class | @@  )\r\n\r\nAudio link:          :: [New song    ](  ./media/audio/eg.oga | eg-link-class | @@  )\r\n\r\nVideo link:          :: [A video     ](  ./media/video/eg.ogv | eg-link-class | @@  )\r\n\r\nWeb page/other:      :: [Buy now     ](  ./my-shop-home-page  | eg-link-class | @@  )\r\n\r\n                     :: [Download    ](  http://download.site/anything.pdf | eg-link-class | @@  )\r\n\r\n                     :: [Read this   ](  http://some.site/anything.pdf     | eg-link-class | @@  )\r\n\r\n### Media tags\r\n\r\n### Image\r\n\r\n[An image](         ./media/image/test.png | eg-image-class )\r\n\r\n### Audio\r\n\r\n[An audio snippet]( ./media/audio/test.oga | ./media/audio/test.mp3 | eg-audio-class )\r\n\r\n### Video\r\n\r\n[A video](          ./media/video/test.webm | ./media/video/test.mp4 | eg-video-class )\r\n\r\n');

CREATE TABLE `swefcms_relation` (
  `relation_Lower_Item_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  `relation_Higher_Item_UUID` varchar(255) CHARACTER SET ascii NOT NULL,
  PRIMARY KEY (`relation_Lower_Item_UUID`,`relation_Higher_Item_UUID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `swefcms_relation` (`relation_Lower_Item_UUID`, `relation_Higher_Item_UUID`) VALUES
('0a719714-c79a-11e7-9428-d8d3859a9e13',  '0a719f5d-c79a-11e7-9428-d8d3859a9e13'),
('0a719f5d-c79a-11e7-9428-d8d3859a9e13',  '0a71b5b1-c79a-11e7-9428-d8d3859a9e13');
