
swefcms = {

    CSSClassUnsaved           : 'unsaved'
   ,dialogue                  : null
   ,initialised               : null
   ,itemForm                  : null
   ,log                       : console.log
   ,parserError               : null
   ,parserFunction            : null
   ,parserInput               : null
   ,parserInputScrollTopMax   : null
   ,parserMarkupTagsSC        : [
        'area','br','hr','img','menuitem','param','source','track','wbr'
    ]
   ,parserMaxLines            : 1024
   ,parserTextBlockElement    : 'p'
   ,parserTitleIn             : null
   ,parserTitleOut            : null
   ,parserOutput              : null
   ,parserOutputScrollTopMax  : null
   ,parserViewMode            : 'rich'

   ,_init : function (maxLines,pFunc) {
        if (this.initialised) {
            return;
        }
        if (swef==undefined || typeof(swef)!='object') {
            console.log ('swef was not available');
            return;
        }
        if (maxLines) {
            this.parserMaxLines         = maxLines;
        }
        this.console                    = document.getElementById ('swefcms-console');
        if (this.console) {
            var c                       = this.console;
            this.log                    = function (msg) {
                c.innerHTML             = msg;
            };
        }
        this.itemTitle                  = document.getElementById ('swefcms-item-title');
        this.parserInput                = document.getElementById ('swefcms-markdown');
        if (!this.parserInput) {
            console.log ('Element id="swefcms-markdown" was not found');
            return;
        }
        this.parserOutput               = document.getElementById ('swefcms-markup');
        if (!this.parserOutput) {
            console.log ('Element id="swefcms-markup" was not found');
            return;
        }
        this.dialogue                   = document.getElementById ('swefcms-unload');
        this.parserTitleIn              = document.getElementById ('swefcms-title-input');
        this.parserTitleOut             = document.getElementById ('swefcms-title');
        this.parserButtonCheckout       = document.getElementById ('swefcms-button-check-out');
        this.parserButtonSave           = document.getElementById ('swefcms-markdown-save');
        this.parserButtonR              = document.getElementById ('swefcms-button-rendered');
        this.parserButtonS              = document.getElementById ('swefcms-button-source');
        this.parserSelectLanguage       = document.getElementById ('swef-cms-select-language');
        this.parserSelectVersion        = document.getElementById ('swef-cms-select-version');
        this.parserSet (pFunc);
        this.parserFunction ();
        this.parserButtonCheckout.addEventListener  ('click',   this.checkOut);
        this.parserButtonR.addEventListener         ('click',   this.parserRendered);
        this.parserButtonS.addEventListener         ('click',   this.parserSource);
        this.parserInput.addEventListener           ('scroll',  this.parserScrollOutput);
        this.parserOutput.addEventListener          ('scroll',  this.parserScrollInput);
        this.parserInput.addEventListener           ('input',   this.parserChange);
        this.parserTitleIn.addEventListener         ('input',   this.parserFunction);
        this.parserSelectLanguage.addEventListener  ('change',  this.langSwitch);
        this.initialised                = true;
        this.log ('SwefCMS initialised');
    }

   ,checkOutCallback : function (xhr,args) {
        swef.unwait ();
        var form            = args[0];
        var action          = args[1];
        if (xhr.status!=200) {
            console.log ('API HTTP status: '+xhr.status);
            if (action=='checkout') {
                swef.notify ('Failed to confirm check out for this language/version');
            }
            else {
                swef.notify ('Failed to confirm check in for this language/version');
            }
            return;
        }
        try {
            var json    = JSON.parse (xhr.responseText);
        }
        catch (e) {
            console.log ('Could not parse JSON:');
            console.log (xhr.responseText);
            return;
        }
        console.log (json);
        if (json.results[0].status!=200) {
            if (action=='checkout') {
                console.log ("Procedure \\Swef\\SwefCMS::apiLanguageCheckOut() status: "+json.results[0].status);
                swef.notify ('Failed to check out this language/version');
            }
            else {
                console.log ("Procedure \\Swef\\SwefCMS::apiLanguageCheckIn() status: "+json.results[0].status);
                swef.notify ('Failed to check in this language/version');
            }
        }
    }

   ,escapeHTML : function (str) {
        return swef.escapeHTML (str);
    }

   ,itemSave : function (form) {
        var active  = 0;
        if (form.active.checked) {
            active  = 1;
        }
        var order   = parseInt (form.order.value.trim());
        if (isNaN(order)) {
            order   = 0;
        }
        var json    = {
            procedures    : [
                [ "\\Swef\\SwefCMS::apiItemUpdate", form.item_uuid.value, active, order ]
               ,[ "\\Swef\\SwefCMS::apiItemProperties", form.item_uuid.value ]
            ]
        };
        swef.apiSend (json,this.itemSaveCallback,[form,this.itemTitle]);
        swef.wait ();
    }

   ,itemSaveCallback : function (xhr,args) {
        swef.unwait ();
        var form        = args[0];
        var title       = args[1];
        if (xhr.status!=200) {
            console.log ('API HTTP status: '+xhr.status);
            swef.notify ('Failed to save item');
            return;
        }
        try {
            var json    = JSON.parse (xhr.responseText);
        }
        catch (e) {
            console.log ('Could not parse JSON:');
            console.log (xhr.responseText);
            return;
        }
        console.log (json);
        if (json.results[0].status!=200) {
            console.log ("Procedure \\Swef\\SwefCMS::apiItemUpdate() status: "+json.results[0].status);
            swef.notify ('Failed to save item');
        }
        if (json.results[1].status!=200) {
            console.log ("Procedure \\Swef\\SwefCMS::apiItemProperties() status: "+json.results[1].status);
            swef.notify ('Failed to retrieve item');
            return;
        }
        if (json.results[1].data['active']) {
            form.active.checked = true;
            title.classList.remove ('inactive');
        }
        else {
            form.active.checked = false;
            title.classList.add ('inactive');
        }
    }

   ,langSwitch : function (evt) {
        swef.wait ();
        self.location.href  = evt.currentTarget.value;
    }

   ,parseEmStrong : function (str) {
        while (1) {
            match           = str.match ( /^([^*]*)\*([^*]+)\*([^*].*)?$/ );
            if (!match) {
                break;
            }
            str             = '';
            if (match[1]!=undefined) {
                str         = match[1];
            }
            str            += '<em>'+match[2]+'</em>';
            if (match[3]!=undefined) {
                str        += match[3];
            }
        }
        while (1) {
            match           = str.match ( /^([^*]*)\*\*([^*]+)\*\*([^*].*)?$/ );
            if (!match) {
                break;
            }
            str             = '';
            if (match[1]!=undefined) {
                str         = match[1];
            }
            str            += '<strong>'+match[2]+'</strong>';
            if (match[3]!=undefined) {
                str        += match[3];
            }
        }
        return str;
    }

   ,parseList : function (arr) {
       if (!arr.length) {
           return '';
       }
       var ns       = [];
       var tn       = arr[0][0];
       var bf       = '<'+tn+'>';
       var pt       = 0;
       while (pt in arr) {
           ns       = [];
           while (pt in arr && arr[pt][0]!=tn) {
               ns.push (arr[pt]);
               pt++;
           }
           bf       += this.parseList (ns);
           if (pt in arr) {
               bf   += '<li>'+arr[pt][1]+'</li>';
           }
           pt++;
       }
       bf           += '</'+tn+'>';
       return bf;
    }

   ,parseMarkdown : function (cms) {
        // Segment types
        var blocksep    =  0;
        var unparsed    =  1;
        var markup      =  2;
        var anchor      =  3;
        var heading     =  4;
        var resource    =  5;
        var horizr      =  6;
        var table       =  7;
        var list        =  8;
        var label       =  9;
        var emphasis    = 10;
        var strong      = 11;
        // Behaviour types
        var embed       = 0;
        var linkto      = 1;
        var newwindow   = 2;
        // Matching variables
        var match;
        // Block tags
        var blockTags   = [blocksep,anchor,heading,horizr,table,list];
        // Start
        var ip          = cms.parserInput.value.trim ();
            ip          = ip.replace ("\t","  ");
            ip          = ip.replace ("\r\n","\n");
            ip          = ip.replace ("\r","\n");
            ip          = ("\n"+ip+"\n").split ("\n");
        // Set block separators
        var pt          = 0;
        var op          = [];
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (set blocks)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (!ip[pt].trim ().length) {
                op.push ([blocksep,'']);
                pt++;
                continue;
            }
            op.push ([unparsed,ip[pt]]);
            pt++;
        }
        // PASS = markup (passed through)
        var tag;
        var bf          = '';
        var sc          = false;
        pt              = 0;
        ip              = op;
        op              = [];
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (mark-up pass-through)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (ip[pt][0]!=unparsed) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            // Match end of self-closing tag
            if (sc) {
                match       = ip[pt][1].match ( /^(.*)>(.*)$/ );
                if (match!==null) {
                    op.push ([markup,(bf+' '+match[1]+'>')]);
                    tag     = null;
                    sc      = null;
                    bf      = null;
                    if (match[2].trim().length===0) {
                        op.push ([blocksep,'']);
                        pt++;
                        continue;
                    }
                    bf     += match[2];
                    continue;
                }
                bf         += ip[pt][1];
                pt++;
                continue;
            }
            // Match close tag
            if (tag) {
                var re  = new RegExp ( '^(.*)</('+tag+'[^\s]*>)(.*)$', 'i' );
                match   = ip[pt][1].match ( re );
                if (match!==null) {
                    op.push ([markup,(bf+match[1]+'</'+tag+'>')]);
                    tag = null;
                    bf  = null;
                    if (match[3]==undefined || match[3].trim().length==0) {
                        op.push ([blocksep,'']);
                        pt++;
                        continue;
                    }
                    bf += match[3];
                    continue;
                }
                bf     += ip[pt][1];
                pt++;
                continue;
            }
            // Match open tag start
            match       = ip[pt][1].match ( /^([^<]*)<([a-z0-9\-]*)(.*)$/i );
            if (!match || !match[2].length) {
                op.push ([unparsed,ip[pt][1]]);
                pt++;
                continue;
            }
            if (match[1].trim().length==0) {
                op.push ([blocksep,'']);
            }
            else {
                op.push ([unparsed,match[1]]);
            }
            tag                 = match[2];
            // Match self-closing tag to list
            if (cms.parserMarkupTagsSC.indexOf(tag)!==-1) {
                sc              = true;
            }
            bf                  = '<' + tag;
            ip[pt][1]           = '';
            if (match[3]!==undefined) {
                ip[pt][1]      += match[3];
            }
        }
        // Pass 2 - anchors
        pt              = 0;
        ip              = op;
        op              = [];
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (anchors)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (ip[pt][0]!=unparsed) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            // Match resource pattern start @anchorname  - no space between @ and anchorname
            match               = ip[pt][1].match ( /^[\s]*@([^\s]*)[\s]*$/ );
            if (!match || match[1].trim().length==0) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            op.push ([blocksep,'']);
            op.push ([anchor,'<a name="'+cms.esc(match[1])+'"></a>']);
            op.push ([blocksep,'']);
            pt++;
        }
        // PASS = tables
        var tbl                 = null;
        bf                      = '';
        pt                      = 0;
        ip                      = op;
        op                      = [];
        num                     = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (mark-up pass-through)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (ip[pt][0]!=unparsed) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            match               = ip[pt][1].match ( /^\s*([\{|\||\}])(.*)$/ );
            if (!match) {
                if (tbl) {
                    // Finish table
                    bf         += '</table>';
                    op.push ([table,bf]);
                    op.push ([blocksep,'']);
                    tbl         = null;
                    bf          = '';
                    match       = ip[pt][1].match ( /^\s*[=|\-]+/ );
                    if (!match) {
                        op.push (ip[pt]);
                    }
                    pt++;
                    continue;
                }
                else {
                    op.push (ip[pt]);
                    pt++;
                    continue;
                }
            }
            if (!tbl) {
                // Start table
                tbl             = [];
                var match       = ip[(1*pt)-1][1].match ( /^\s*[=|\-]+/ );
                if (match) {
                    op.pop ();
                }
                op.push ([blocksep,'']);
                bf              = '<table>';
            }
            bf                 += '<tr>';
            var str             = ip[pt][1];
            var sep;
            var c;
            var cell;
            var test;
            while (1) {
                if (!str.trim().length) {
                    break;
                }
                match           = str.match ( /^\s*([}|{])(.*)$/ );
                if (!match) {
                    if (match[2]==undefined || !match[2].trim().length) {
                        match[2] = '&nbsp;';
                    }
                    else {
                        match[2] = cms.parseEmStrong (cms.esc(match[2]));
                    }
                    bf         += '<td class="'+c+'">'+match[2]+'</td>';
                    break;
                }
                sep             = match[1];
                match = match[2].match ( /^([^}|{]*)([}|{]?)(.*)$/ );
                if (match && match[1]!=undefined && match[1].trim().length) {
                    cell        = cms.parseEmStrong (cms.esc(match[1]));
                }
                else {
                    cell        = '&nbsp;';
                }
                if (sep=='{') {
                    c           = 'left';
                }
                else if (sep=='|') {
                    c           = 'center';
                }
                else if (sep=='}') {
                    c           = 'right';
                }
                bf             += '<td class="'+c+'">'+cell+'</td>';
                str             = '';
                if (!match || match[2]==undefined) {
                    break;
                }
                if (!match[3].trim().length) {
                    break;
                }
                str             = match[2] + match[3];
            }
            bf                 += '</tr>';
            pt++;
        }
        // PASS = lists
        var lst;
        var str;
        bf                      = [];
        pt                      = 0;
        ip                      = op;
        op                      = [];
        num                     = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (mark-up pass-through)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (ip[pt][0]!=unparsed) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            match               = ip[pt][1].match ( /^\s*(\*|[0-9]+\.)\s+(.*)\s*$/ );
            if (!match) {
                if (lst) {
                    // Finish list
                    op.push ([list,cms.parseList(bf)]);
                    op.push ([blocksep,'']);
                    lst         = null;
                    bf          = [];
                    continue;
                }
                else {
                    op.push (ip[pt]);
                    pt++;
                    continue;
                }
            }
            if (!lst) {
                // Start list
                lst             = true;
                op.push ([blocksep,'']);
            }
            if (match[1]=='*') {
                match[1] = 'ul';
            }
            else {
                match[1] = 'ol';
            }
            bf.push ([match[1],match[2]]);
            pt++;
        }
        // PASS = <hr>
        var n                   = 1;
        ip                      = op;
        op                      = [];
        pt                      = 1; // Looks back to previous line
        num                     = 0;
        op.push ([blocksep,'']);
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (headings)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            // Horizontal rule must be preceded by blocksep
            if (ip[(1*pt)-1][1]!=blocksep) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            var match           = ip[pt][1].match ( /^([=|\-]+)\s*$/ );
            if (!match) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            if (match[1].indexOf('-')==0) {
                n       = 2;
            }
            op.push ([blocksep,'']);
            op.push ([horizr,'<hr class="hr-'+n+'" />']);
            op.push ([blocksep,'']);
            pt++;
        }
        // PASS = <h[n]>
        var mprev;
        var n                   = 1; // <h1> is default </h1>
        ip                      = op;
        op                      = [];
        pt                      = 1; // Headers are handled as *previous* line (1st ln always blocksep)
        num                     = 0;
        op.push ([blocksep,'']);
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (headings)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            // Headers are handled as *previous* line
            if (ip[(1*pt)-1][0]!=unparsed) {
                op.push (ip[(1*pt)-1]);
                pt++;
                continue;
            }
            mprev               = ip[(1*pt)-1][1].match ( /^(#+)\s*(.+)\s*/ );
            match               = ip[pt][1].match ( /^\s*([=|\-]+)\s*$/ );
            if (!mprev && !match) {
                op.push (ip[(1*pt)-1]);
                pt++
                continue;
            }
            op.push ([blocksep,'']);
            if (mprev) {
                op.push ([heading,'<h'+mprev[1].length+'>'+mprev[2]+'</h'+n+'>']);
            }
            else {
                if (match[1].indexOf('-')==0) {
                    n           = 2;
                }
                op.push ([heading,'<h'+n+'>'+ip[(1*pt)-1][1].trim()+'</h'+n+'>']);
            }
            op.push ([blocksep,'']);
            pt++;
            if (match) {
                pt++;
            }
            continue;
        }
        op.push ([blocksep,'']);
        // PASS = labels
        pt              = 0;
        ip              = op;
        op              = [];
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (resources)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (ip[pt][0]!=unparsed) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            // Match tab/label pattern
            match               = ip[pt][1].match ( /^(.*)\s+(:+)(\s+)(.*)$/ );
            if (!match) {
                match           = ip[pt][1].match ( /^(\s*)(:+)(\s+)(.*)$/ );
                if (!match) {
                    op.push ([unparsed,ip[pt][1]]);
                    pt++;
                    continue;
                }
            }
            if (match[1]!=undefined && match[1].trim().length>0) {
                match[1] = cms.parseEmStrong (cms.esc(match[1]));
            }
            else {
                match[1] = '&nbsp;';
            }
            op.push ([label,'<div class="labelled-item"><label class="label-'+match[2].length+'">'+match[1]+'</label>']);
            if (match[4]!=undefined && match[4].trim().length>0) {
                op.push ([unparsed,match[4].trim()]);
            }
            op.push ([label,'</div>']);
            pt++;
        }
        // PASS = resources
        pt              = 0;
        ip              = op;
        op              = [];
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (resources)';
                return cms.parserError;
            }
            if (pt>=ip.length) {
                break;
            }
            if (ip[pt][0]!=unparsed) {
                op.push (ip[pt]);
                pt++;
                continue;
            }
            // Match resource pattern [ Title ]( link1 | ...linkN | classname | @@ )  - no space between ] and (
            match               = ip[pt][1].match ( /^(.*)\[([^\]]*)\]\(([^\)]*)\)(.*)$/ );
            if (!match || match[2].trim().length===0) {
                op.push ([unparsed,ip[pt][1]]);
                pt++;
                continue;
            }
            if (match[1].trim().length>0) {
                op.push ([unparsed,match[1]]);
            }
            if (match[4]!==undefined && match[4].trim().length!=0) {
                ip[pt][1]       = match[4];
            }
            else {
                pt++;
            }
            var data            = {};
            data.title          = match[2].split ('|');
            if (data.title.length==1) {
                data.caption    = data.title[0].trim ();
            }
            else {
                data.caption    = data.title[1].trim ();
            }
            data.title          = data.title[0].trim ();
            data.params         = match[3].split ('|');
            for (i in data.params) {
                data.params[i]  = data.params[i].trim ();
            }
            data.type           = data.params[data.params.length-1];
            if (data.type.indexOf('@')==0) {
                if (data.type==='@') {
                    data.type   = linkto;
                }
                else {
                    data.type   = newwindow;
                }
                data.params.pop ();
            }
            else {
                data.type       = embed;
            }
            data.class          = data.params[data.params.length-1];
            if (data.class.match( /^([a-z0-9\-_])+$/i )) {
                data.params.pop ();
            }
            else {
                data.class      = null;
            }
            if (data.type==embed) {
                match = data.params[0].match ( /\.(bmp|gif|jpeg|jpg|png)$/ );
                if (match) {
                    var res = '<figure class="image '+cms.esc(data.class)+'"><img src="'+cms.esc(data.params[0])+'" alt="'+cms.esc(data.caption)+'" /><figcaption>'+cms.parseEmStrong(cms.esc(data.title))+'</figcaption></figure>';
                    op.push ([resource,res]);
                    continue;
                }
                match = data.params[0].match( /\.(mp3|oga|wav)$/ );
                if (match) {
                    var res = '<figure class="audio '+cms.esc(data.class)+'"><audio controls title="'+cms.esc(data.title)+'">';
                    var i = 0;
                    while (i in data.params) {
                        if (i==0) {
                            var ct  = match[1];
                        }
                        else {
                            var ct  = data.params[i].match ( /\.([^\.]+)$/ );
                            if (ct) {
                                ct  = ct[1];
                            }
                        }
                        if (!ct) {
                            i++;
                            continue;
                        }
                        if (ct=='mp3') {
                            ct  = 'x-mpeg';
                        }
                        else if (ct=='oga') {
                            ct  = 'ogg';
                        }
                        res += '<source src="'+cms.esc(data.params[i])+'" type="audio/'+ct+'" />';
                        i++;
                    }
                    res += '</audio><figcaption>'+cms.parseEmStrong(cms.esc(data.caption))+'</figcaption></figure>';
                    op.push ([resource,res]);
                    continue;
                }
                match = data.params[0].match( /\.(mp4|ogg|ogv|webm)$/ );
                if (match) {
                    var res = '<figure class="video '+cms.esc(data.class)+'"><video controls title="'+cms.esc(data.title)+'">';
                    var i = 0;
                    while (i in data.params) {
                        if (i==0) {
                            var ct  = match[1];
                        }
                        else {
                            var ct  = data.params[i].match ( /\.([^\.]+)$/ );
                            if (ct) {
                                ct  = ct[1];
                            }
                        }
                        if (!ct) {
                            i++;
                            continue;
                        }
                        if (ct=='ogv') {
                            ct  = 'ogg';
                        }
                        res += '<source src="'+cms.esc(data.params[i])+'" type="video/'+ct+'" />';
                        i++;
                    }
                    res += '</video><figcaption>'+cms.parseEmStrong(cms.esc(data.caption))+'</figcaption></figure>';
                    op.push ([resource,res]);
                    continue;
                }
                data.type = linkto;
            }
            if (data.type==linkto) {
                var res = '<a href="'+cms.esc(data.params[0])+'" title="'+cms.esc(data.caption)+'" class="'+cms.esc(data.class)+'">'+cms.parseEmStrong(cms.esc(data.title))+'</a>';
                op.push ([resource,res]);
                continue;
            }
            else {
                var res = '<a target="_blank" href="'+cms.esc(data.params[0])+'" title="'+cms.esc(data.caption)+'" class="'+cms.esc(data.class)+'">'+cms.parseEmStrong(cms.esc(data.title))+'</a>';
                op.push ([resource,res]);
                continue;
            }
        }
        // Remove repeat block separators
        pt              = 0;
        ip              = op;
        op              = [];
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (remove repeat blocks)';
                return cms.parserError;
            }
            if (pt>ip.length-2) {
                break;
            }
            if (ip[pt][0]==blocksep && ip[(1*pt)+1][0]==blocksep) {
                pt++;
                continue;
            }
            op.push (ip[pt]);
            pt++;
        }
        op.push ([blocksep,'']);
        ip              = op;
        op              = [];
        pt              = 0;
        num             = 0;
        while (1) {
            num++;
            if (num>=cms.parserMaxLines) {
                cms.parserError = 'Number of lines exceeded '+cms.parserMaxLines+' (remove repeat blocks)';
                return cms.parserError;
            }
            if (pt>ip.length-2) {
                break;
            }
            if (ip[pt][0]==unparsed) {
                // Escape for HTML then parse em and strong
                ip[pt][1]       = cms.parseEmStrong (cms.esc(ip[pt][1]));
                // Parse spaces
                while (ip[pt][1].indexOf(' _ ')>-1) {
                    ip[pt][1]   = ip[pt][1].replace (' _ ','&nbsp;&nbsp;');
                }
                // Parse line breaks
                match           = ip[pt][1].match ( /^(.*)[\s+][\\|\/]\s*$/ );
                if (match) {
                    if (match[1]==undefined) {
                        match[1] = '';
                    }
                    ip[pt][1]   = match[1] + '<br/>';
                }
                // Block start
                if (ip[(1*pt)-1][0]==blocksep) {
                    ip[pt][1]       = '<' + cms.parserTextBlockElement + '>' + ip[pt][1];
                }
                // Block end
                if (ip[(1*pt)+1][0]==blocksep) {
                    ip[pt][1]       = ip[pt][1] + '</' + cms.parserTextBlockElement + '>';
                }
            }
            if (ip[pt][0]!=blocksep) {
                op.push (ip[pt][1]);
            }
            pt++;
        }
        // Finished, return in correct format
        var rtn = '';
        for (pt in op) {
            if (cms.parserViewMode=='rich') {
                rtn += ' ' + op[pt];
            }
            else {
                rtn += cms.esc(op[pt]) + "<br/>\r\n";
            }
        }
        return rtn;
    }

   ,parserChange : function (evt) {
        if (event.type=='input' && window.onbeforeunload==null) {
            window.onbeforeunload       = function ( ) {
                return 'Changes are unsaved. Quit anyway?';
            };
            this.parserInput.classList.add    (this.CSSClassUnsaved);
            this.parserTitleIn.classList.add  (this.CSSClassUnsaved);
        }
        this.parserFunction ();
    }

   ,parserSet : function (pFunc) {
        if (pFunc==null) {
            pFunc                           = this.parseMarkdown;
        }
        if (typeof(pFunc)!='function') {
            console.log ('"'+pFunc+'" is not a function');
            return false;
        }
        this.esc            = swef.escapeHTML;
        this.parserFunction = (
            function ( ) {
                console.log ('Parse using '+pFunc.name+'()');
                this.parserOutput.innerHTML     = pFunc (this);
                this.parserTitleOut.innerHTML   = this.esc (this.parserTitleIn.value);
                this.parserInputScrollTopMax    = this.parserInput.scrollHeight;
                this.parserInputScrollTopMax   += this.parserInput.style.borderTopWidth;
                this.parserInputScrollTopMax   -= this.parserInput.offsetHeight;
                this.parserOutputScrollTopMax   = this.parserOutput.scrollHeight;
                this.parserOutputScrollTopMax  += this.parserOutput.style.borderTopWidth;
                this.parserOutputScrollTopMax  -= this.parserOutput.offsetHeight;
            }
        ).bind (this);
        this.parserRendered = (
            function (ev) {
                console.log ('Setting view to rendered HTML');
                this.viewMode (false);
                this.parserFunction ();
                ev.preventDefault ();
            }
        ).bind (this);
        this.parserSource = (
            function (ev) {
                console.log ('Setting view to source code');
                this.viewMode (true);
                this.parserFunction ();
                ev.preventDefault ();
            }
        ).bind (this);
        this.parserScrollInput = (
            function ( ) {
                this.parserInput.scrollTop     = Math.round (this.parserInputScrollTopMax*this.parserOutput.scrollTop/this.parserOutputScrollTopMax);
            }
        ).bind (this);
        this.parserScrollOutput = (
            function ( ) {
                this.parserOutput.scrollTop    = Math.round (this.parserOutputScrollTopMax*this.parserInput.scrollTop/this.parserInputScrollTopMax);
            }
        ).bind (this);
        this.checkOut = (
            function (evt) {
                var elmt        = evt.currentTarget;
                var action      = elmt.getAttribute ('data-action');
                var itemUUID    = elmt.form.item_uuid.value;
                var lng         = this.parserSelectLanguage.options[this.parserSelectLanguage.selectedIndex];
                var vn          = this.parserSelectVersion.options[this.parserSelectVersion.selectedIndex];
                if (action='checkout') {
                    var json    = {
                        procedures    : [
                            [ "\\Swef\\SwefCMS::apiLanguageCheckOut", swef.userUUID, itemUUID, lng, vn ]
                        ]
                    };
                    elmt.setAttribute ('data-action','checkin');
                }
                else {
                    var json    = {
                        procedures    : [
                            [ "\\Swef\\SwefCMS::apiLanguageCheckIn", swef.userUUID, itemUUID, lng, vn ]
                        ]
                    };
                    elmt.setAttribute ('data-action','checkout');
                }
                var val   = elmt.nodeValue;
                var nVal  = elmt.getAttribute ('data-next-value');
                elmt.setAttribute ('data-next-value',val);
                elmt.nodeValue = nVal;
                swef.apiSend (json,this.checkOutCallback,[elmt.form,action]);
                swef.wait ();

            }
        ).bind (this);
        this.parserButtonSave.addEventListener (
            'click'
           ,function ( ) { window.onbeforeunload = null; }
        );
    }

   ,versionSwitch : function (evt) {
        swef.wait ();
        self.location.href  = evt.currentTarget.value;
    }

   ,viewMode : function (source) {
        if (source) {
            this.parserViewMode                 = 'source';
            console.log ('viewMode() set view to HTML source code, parserViewMode='+this.parserViewMode);
        }
        else {
            this.parserViewMode                 = 'rich';
            console.log ('viewMode() set view to rendered HTML, parserViewMode='+this.parserViewMode);
        }
    }

}

