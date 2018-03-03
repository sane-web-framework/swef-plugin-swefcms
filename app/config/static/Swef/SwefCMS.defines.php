<?php

// Text processing
define ( 'swefcms_charset',                        'UTF-8'                                              );

// Javascript API
define ( 'swefcms_api_item_save',                   'SwefCMS::itemSave'                                 );

// Stored procedures
define ( 'swefcms_call_check_out',                  'swefCMSCheckOut'                                   );
define ( 'swefcms_call_children',                   'swefCMSChildren'                                   );
define ( 'swefcms_call_collection',                 'swefCMSCollection'                                 );
define ( 'swefcms_call_collection_new',             'swefCMSCollectionNew'                              );
define ( 'swefcms_call_collections',                'swefCMSCollections'                                );
define ( 'swefcms_call_item',                       'swefCMSItem'                                       );
define ( 'swefcms_call_item_new',                   'swefCMSItemNew'                                    );
define ( 'swefcms_call_item_update',                'swefCMSItemUpdate'                                 );
define ( 'swefcms_call_language_new',               'swefCMSLanguageNew'                                );
define ( 'swefcms_call_markdown',                   'swefCMSMarkdown'                                   );
define ( 'swefcms_call_markdown_new',               'swefCMSMarkdownNew'                                );
define ( 'swefcms_call_markdown_source',            'swefCMSMarkdownSource'                             );
define ( 'swefcms_call_markdowns',                  'swefCMSMarkdowns'                                  );
define ( 'swefcms_call_read',                       'swefCMSRead'                                       );
define ( 'swefcms_call_relation_add',               'swefCMSRelationAdd'                                );
define ( 'swefcms_call_relation_remove',            'swefCMSRelationRemove'                             );
define ( 'swefcms_call_relations',                  'swefCMSRelations'                                  );

// Map data row array keys to stored procedure fields
define ( 'swefcms_col_active',                      'active'                                            );
define ( 'swefcms_col_children',                    'children'                                          );
define ( 'swefcms_col_collection',                  'collection'                                        );
define ( 'swefcms_col_created',                     'created'                                           );
define ( 'swefcms_col_creator',                     'creator'                                           );
define ( 'swefcms_col_creator_uuid',                'creator_uuid'                                      );
define ( 'swefcms_col_is_collection',               'is_collection'                                     );
define ( 'swefcms_col_is_editable',                 'is_editable'                                       );
define ( 'swefcms_col_is_live',                     'is_live'                                           );
define ( 'swefcms_col_item_uuid',                   'item_uuid'                                         );
define ( 'swefcms_col_markdown',                    'markdown'                                          );
define ( 'swefcms_col_markdown_source',             'markdown_source'                                   );
define ( 'swefcms_col_markdowns',                   'markdowns'                                         );
define ( 'swefcms_col_mother',                      'mother'                                            );
define ( 'swefcms_col_mother_uuid',                 'mother_uuid'                                       );
define ( 'swefcms_col_order',                       'order'                                             );
define ( 'swefcms_col_published',                   'published'                                         );
define ( 'swefcms_col_relation_uuid',               'relation_uuid'                                     );
define ( 'swefcms_col_relations',                   'relations'                                         );
define ( 'swefcms_col_title',                       'title'                                             );
define ( 'swefcms_col_updated',                     'updated'                                           );
define ( 'swefcms_col_updater',                     'updater'                                           );
define ( 'swefcms_col_updater_uuid',                'updater_uuid'                                      );
define ( 'swefcms_col_may_grant',                   'may_grant'                                         );
define ( 'swefcms_col_may_create',                  'may_create'                                        );
define ( 'swefcms_col_may_update',                  'may_update'                                        );
define ( 'swefcms_col_may_delete',                  'may_delete'                                        );
define ( 'swefcms_col_version',                     'version'                                           );
define ( 'swefcms_col_versions',                    'versions'                                          );
define ( 'swefcms_col_editor_uuid',                 'editor_uuid'                                       );

// UUID pattern
define ( 'swefcms_uuid_preg_match',                 '<^[0-9a-f\-]+$>'                                   );

// Slugs
define ( 'swefcms_slug_uuid_min_length',            36                                                  );
define ( 'swefcms_slug_preg_match',                 '<^/[a-z0-9$\-_.+!]*$>'                             );
define ( 'swefcms_slug_dir_separator',              '~~'                                                );
define ( 'swefcms_slug_spacer',                     '-'                                                 );
define ( 'swefcms_slug_utf8',                       'UTF-8'                                             );
define ( 'swefcms_slug_ascii_translit',             'ASCII//TRANSLIT'                                   );
define ( 'swefcms_slug_strip_preg',                 '<[^a-zA-Z0-9$_+!]>'                                );
define ( 'swefcms_slug_convert_chars',              [
    swefcms_slug_dir_separator  => '+'
   ,swefcms_slug_spacer         => '_'
   ,"\t"                        => ' '
   ,"\r"                        => ' '
   ,"\n"                        => ' '
   ,"'"                         => ' '
   ,'@'                         => ' at '
   ,'£'                         => ' pounds '
   ,'%'                         => ' pct '
   ,'&'                         => ' and '
   ,'?'                         => ' qn'
                                                    ]                                                   );

// Other
    // Prevent accidental infinite recursion
define ( 'swefcms_collection_sane_depth',           10                                                  );
define ( 'swefcms_collections_lookup',              'swefcms-collections'                               );
// Application options available
define ( 'swefcms_dashboard_options_valid',         array ( '', 'collections', 'collection', 'collectionCreate', 'inspect', 'itemEdit', 'items', 'item', 'itemCreate', 'markdown' ) );
// Options for direct user selection
define ( 'swefcms_dashboard_options_select',        array ( ''=>'SwefCMS Options:', 'collections'=>'View all collections', 'markdown'=>'Editor', 'inspect'=>'Inspect plugin properties' ) );
define ( 'swefcms_vendor',                          SWEF_VENDOR_SWEF                                    );

// Files
define ( 'swefcms_file_dash',                       SWEF_DIR_PLUGIN.'/Swef/SwefCMS.dash.html'           );
define ( 'swefcms_file_option_collections',         SWEF_DIR_PLUGIN.'/Swef/SwefCMS.o.collections.html'  );
define ( 'swefcms_file_option_collection',          SWEF_DIR_PLUGIN.'/Swef/SwefCMS.o.collection.html'   );
define ( 'swefcms_file_option_item',                SWEF_DIR_PLUGIN.'/Swef/SwefCMS.o.item.html'         );
define ( 'swefcms_file_option_markdown',            SWEF_DIR_PLUGIN.'/Swef/SwefCMS.o.markdown.html'     );


?>
