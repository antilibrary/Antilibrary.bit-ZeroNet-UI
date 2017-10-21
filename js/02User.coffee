class User extends Class 

    defaultUserData: () =>
        #settings
        @data = {}
        @data.settings = {}

        @data.shelves = []
        @data.shelves[0] = {}
        @data.shelves[0].name = 'Want To Read'
        @data.shelves[0].books = []
        @data.shelves[1] = {}
        @data.shelves[1].name = 'Read'
        @data.shelves[1].books = []
        @data.shelves[2] = {}
        @data.shelves[2].name = 'Pending'
        @data.shelves[2].books = []

        return @data



    saveSettings: (e=null,cb=null,refresh=true) =>
        inner_path = "merged-Antilibrary/#{Page.userDB}/data/users/#{Page.site_info.auth_address}/data.json"
        json_raw = unescape(encodeURIComponent(JSON.stringify(@data)))
        @log json_raw
        
        #debug mode
        # cb(e)

        Page.cmd "fileWrite", [inner_path, btoa(json_raw)], (res) =>
            if res == "ok"
                Page.cmd "sitePublish", {"inner_path": inner_path}, (res) =>
                    #@log res
                    if res == "ok"
                        Page.cmd "wrapperNotification", ["done", "Saved!",3000]
                    cb(e) if cb
            else
                Page.cmd "wrapperNotification", ["error", "File write error: #{res}"]
            
            if Page.showing == "shelves" and refresh
                Search.executeSearch('shelves')
            

    loadSettingsFromFile: (cb=null) =>
        if Page.site_info.cert_user_id
            inner_path = "merged-Antilibrary/#{Page.userDB}/data/users/#{Page.site_info.auth_address}/data.json"
            Page.cmd "fileGet", {"inner_path": inner_path, "required": false}, (data) =>
                if data
                    data = JSON.parse(data)
                else
                    data = @defaultUserData()  
                
                @data = data

                if !@data.uploads?
                    @data.uploads = []

                if window.searchResults.upload_added_books?
                    window.searchResults.upload_added_books = @data.uploads

                window.searchResults.data_file_path = "ZeroNet_dir/data/#{Page.userDB}/data/users/#{Page.site_info.auth_address}/data.json"

                cb() if cb
        else
            @data = @defaultUserData()  
            window.searchResults.data_file_path = "<userDB not added>"
            cb() if cb


    handleAddToShelf: (b_id, shelf, cb) =>
        Page.cmd "siteInfo", {}, (site_info) =>
            Page.site_info = site_info
            #Check if a profile is selected
            if not Page.site_info.cert_user_id
                Page.cmd "certSelect", [["zeroid.bit"]]
                Page.cmd "wrapperNotification", ["info", "This feature require a ZeroNet profile. Please select an account and try again.",7000]
                return false

            else
                if "Merger:Antilibrary" not in Page.site_info.settings.permissions 
                    Page.cmd "wrapperNotification", ["info", "Please, authorize the merger site and try again."]
                    Page.cmd "wrapperPermissionAdd", "Merger:Antilibrary"
                    return false

                Page.cmd "mergerSiteList", {}, (merged_sites) =>
                    if not merged_sites[Page.userDB]
                        Page.cmd "mergerSiteAdd", Page.userDB, (res) =>
                            if res == 'ok'
                                @addToShelf(b_id, shelf, cb)

                    else
                        @addToShelf(b_id, shelf, cb)


    addToShelf: (b_id, shelf, cb, skip=false) =>

        if b_id not in @data.shelves[shelf].books
            @log "Adding #{b_id} to #{@data.shelves[shelf].name}"
            @data.shelves[shelf].books.push b_id
        else
            if skip == false
                @log "Removing #{b_id} from #{@data.shelves[shelf].name}"
                index = @data.shelves[shelf].books.indexOf b_id
                @data.shelves[shelf].books.splice index, 1 if index isnt -1

        if skip == false
            for shelf_to_remove in @data.shelves
                #@log "#{shelf_to_remove.name} != #{@data.shelves[shelf].name}"
                if shelf_to_remove.name != @data.shelves[shelf].name
                    index = shelf_to_remove.books.indexOf b_id
                    shelf_to_remove.books.splice index, 1 if index isnt -1
                    #@log "Removed from #{shelf_to_remove.name}"
            
        cb() if cb


    handleToolsImport: (e) =>
        $("#shelves-tools").show()
        $("#user-settings").hide()
        $("#upload-book").hide()
        $("#no_results_found").hide()
        window.searchResults.books = []
        $(".shelf-link").removeClass "shelf-active"
        window.searchResults.show_count = false
        $(".tool-link").removeClass "shelf-active"
        window.searchResults.no_results_found = false                
        $(e).addClass "shelf-active"

    handleUploadBook: (e) =>
        $("#upload-book").show()
        $("#shelves-tools").hide()
        $("#user-settings").hide()
        $("#no_results_found").hide()
        window.searchResults.books = []
        $(".shelf-link").removeClass "shelf-active"
        $(".tool-link").removeClass "shelf-active"
        window.searchResults.no_results_found = false
        window.searchResults.show_count = false
        $(e).addClass "shelf-active"

    handleToolsSettings: (e=null) =>
        window.searchResults.settings = @data.settings
        for setting of window.searchResults.settings
            $("##{setting}").prop('checked',window.searchResults.settings[setting])
        $("#user-settings").show()
        $("#upload-book").hide()
        $("#shelves-tools").hide()
        window.searchResults.show_count = false
        $("#no_results_found").hide()
        window.searchResults.no_results_found = false                

        
        window.searchResults.books = []
        $(".shelf-link").removeClass "shelf-active"
        $(".tool-link").removeClass "shelf-active"
        $(e).addClass "shelf-active"


    handleSettingsChange: (e) =>
        Page.cmd "siteInfo", {}, (site_info) =>
            Page.site_info = site_info
            
            #Check if a profile is selected
            if not Page.site_info.cert_user_id
                Page.cmd "wrapperNotification", ["info", "This feature require a ZeroNet profile. Please select an account and try again."]
                Page.cmd "certSelect", [["zeroid.bit"]]
                @defaultUserData()
                @handleToolsSettings()
                return false
            setting = "{\"#{e.id}\": #{$("##{e.id}").is(':checked')}}"
            @data.settings[e.id] = $("##{e.id}").is(':checked')
            saved = (e) => 
                $("##{e.id}_saved").show()
                hideSaved = () =>
                    $("##{e.id}_saved").hide()
                setTimeout hideSaved,3000
            @saveSettings(e,saved,false)


    queryDB: (g_id, shelf, cb) =>
        @log "Querying ID: #{g_id}"
        Page.cmd "dbQuery", ["SELECT b_id FROM book WHERE g_id = #{g_id}"], (res) =>
            if res.length > 0
                cb(true, shelf, res[0]['b_id'])
            else
                cb(false, shelf, g_id)
    
    handleToolsImportAction: (e) =>
        Page.cmd "siteInfo", {}, (site_info) =>
            Page.site_info = site_info
            
            #Check if a profile is selected
            if not Page.site_info.cert_user_id
                Page.cmd "wrapperNotification", ["info", "This feature require a ZeroNet profile. Please select an account and try again."]
                Page.cmd "certSelect", [["zeroid.bit"]]
                return false

            inner_path = $("#goodreadsExportFile")[0].files[0]
            reader = new FileReader()


            bookPresentOnAL = (res, shelf, b_id) =>

                shelf_index = 0 if shelf == 'to-read'
                shelf_index = 1 if shelf == 'read'

                if res
                    @log "FOUND: #{b_id} for #{shelf}"
                    @addToShelf(b_id,shelf_index,null,true)
                else
                    @log "NOT FOUND: #{b_id} for #{shelf}"
                    @addToShelf([b_id,shelf_index],2,null,true)

                window.searchResults.import_progress_current_value += 1
                window.searchResults.import_progress_label = "Importing your books... #{window.searchResults.import_progress_current_value} books imported"
                if window.searchResults.import_progress_current_value == window.searchResults.import_progress_max_value
                    setTimeout @saveSettings(null,null,false), 5000
                    window.searchResults.import_progress_label = "All done! #{window.searchResults.import_progress_current_value} books imported"
                    window.searchResults.import_action_label = "Done!"
                    
            reader.onload = (f) =>
                parsed = $.csv.toArrays(reader.result)
                window.searchResults.import_progress_max_value = parsed.length
                window.searchResults.import_action_label = "Please wait..."
                window.searchResults.import_action_disabled = true

                for book in parsed
                    if !isNaN book[0]
                        @queryDB(book[0], book[18], bookPresentOnAL)


            reader.readAsText(inner_path)
            

    checkPendingShelf: =>
        @ct = 0
        @total = @data.shelves[2].books.length
        @found_any_book = false
        if @data.shelves[2].books.length > 0
            bookPresent = (res, shelf, b_id) =>
                if res
                    @log "FOUND: #{b_id} for #{shelf}"
                    @addToShelf(b_id,shelf,null,true)
                    window.alert.msg = '<strong>Pending books found in the database!</strong><br>Some books from your Pending shelf have been added to the database. They have been moved from the Pending shelf to the shelf you had them on your Goodreads (Want To Read or Read).'
                    window.alert.class_type = 'alert-success'
                    window.alert.visible = true
                    @data.shelves[2].books.shift()
                    @found_any_book = true
                else
                    @log "NOT FOUND: #{b_id} for #{shelf}"
                    if b_id == 0
                        @data.shelves[2].books.shift()
                        @found_any_book = true


                @ct += 1
                if @ct == @total and @found_any_book
                    @log "DONE!"
                    @saveSettings()
                    

            for book in @data.shelves[2].books
                @log "Checking pending: #{book[0]}"
                @queryDB(book[0], book[1], bookPresent)
                

    handleRequestBook: (b_f_id) =>
        @log "Book requested: #{b_f_id}"

        if !@data.requests?
            @data.requests = []

        @data.requests.push b_f_id
        Book.showFilesInModal()
        @saveSettings()


    queryFile: (b_f_id,cb) =>
        @log "Checking file: #{b_f_id}"
        Page.cmd "dbQuery", ["SELECT * FROM book_file as bf JOIN book as b ON bf.b_id = b.b_id WHERE b_f_id = #{b_f_id}"], (res) =>
            cb(res[0])

    checkRequests: () =>
        @log "Checking requests..."

        requestPosted = (book) =>
            #fix issue when seeds == 0
            if book['i_s']
                if book['i_s'].length > 1
                    @log "Book online:: #{book['b_f_id']}"
                    @request_list.push "<li>#{book['ft'].toUpperCase()} (#{bytesToSize(book.fs)}) for book <strong><a href=\"#\" onclick=\"window.Book.showBook(#{book['b_id']})\" data-toggle=\"modal\" data-target=\"book-modal\" class=\"ebook-link\">#{book['t']}</a></strong></li>"

                    #remove b_f_id
                    index = @data.requests_posted.indexOf book['b_f_id']
                    @data.requests_posted.splice index, 1 if index isnt -1

            else
                @log "Book still offline! #{book['b_f_id']}"

            @rct += 1
            if @rct == @total_requests and @request_list.length > 0
                window.alert.msg = "<strong>Requested books files added!</strong> The files you requested are now online: <br><br><ul>#{@request_list.join(' ')}</ul>"
                window.alert.class_type = 'alert-info'
                window.alert.visible = true
                @saveSettings()


        if @data.requests_posted?
            @request_list = []
            @total_requests = @data.requests_posted.length
            @rct = 0
            for b_f_id in @data.requests_posted
                @queryFile(b_f_id,requestPosted)

        @log "Checking requests...DONE!"



    handleUploadBookAction: (e) =>
        Page.cmd "siteInfo", {}, (site_info) =>
            Page.site_info = site_info

            #Check if a profile is selected
            if not Page.site_info.cert_user_id
                Page.cmd "wrapperNotification", ["info", "This feature require a ZeroNet profile. Please select an account and try again."]
                Page.cmd "certSelect", [["zeroid.bit"]]
                return false

            saved = (e) => 
                $("#upload_saved").show()
                hideSaved = () =>
                    $("#upload_saved").hide()
                setTimeout hideSaved,3000

            if $("#upload_ipfs_hash").val() == '' or $("#goodreads_id").val() == ''
                return


            @data.uploads.unshift {"ipfs_hash": $("#upload_ipfs_hash").val().trim(),"goodreads_id":$("#goodreads_id").val().trim(),"file_status":"pending"}
            @saveSettings(e,saved,false)
            $("#upload_ipfs_hash").val('')
            $("#goodreads_id").val('')




window.User = new User()