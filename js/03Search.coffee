class Search extends Class


    executeSearch: (search_type='',search_string='',offset=null) ->
        @log "Searching for: #{search_type} - #{search_string}"

        window.scrollTo(0, 0);
        page = window.location.search.substring(1).match(/p=(\d+)/)
        if page
            page = parseInt(page[1])
        else
            page = 0

        if offset?
            window.searchResults.offset = offset
        else
            window.searchResults.offset = parseInt(page)

        #@log "OFFSET: #{window.searchResults.offset}"
        if window.searchResults.offset > 0
            #replace url
            url = window.location.search.substring(1).replace(/.*/,"p=#{window.searchResults.offset}")
            Page.cmd "wrapperReplaceState", ["", "", url]

        #clear books list
        window.searchResults.books = []
        window.searchResults.no_results_found = false
        window.searchResults.show_count = false

        #show loading
        window.searchResults.show_loading = true

        $("#shelves-tools").hide()
        $("#user-settings").hide()
        $("#upload-book").hide()
        $("#no_results_found").show()
        $(".tool-link").removeClass "shelf-active"

        if Object.keys(window.searchResults.shelves).length == 0
            window.searchResults.shelves = User.data.shelves

        if search_type
            window.searchResults.search_type = search_type


        if window.searchResults.search_type == 'keywords' or window.searchResults.search_type == 'latest'
            Page.viewPage('search-container')
            #set search input value
            $("#search-string").val(search_string)

            if search_string
                window.searchResults.nothing_found_error = "No books found!"
                window.searchResults.search_string = search_string
                window.searchResults.search_header = "Search for: "
                window.searchResults.offset = null
                where = " WHERE (book.t LIKE '%#{search_string}%' OR author.n LIKE '%#{search_string}%') LIMIT 1000"
            else
                window.searchResults.show_count = false
                window.searchResults.search_string = ''
                window.searchResults.search_header = "Latest books added"
                where = ' ORDER BY book.b_id desc LIMIT 100'
                window.searchResults.nothing_found_error = "<p class=\"lead\">No books found! <br>Maybe you have just downloaded the site? If so, please go to <a href=\"#\" onclick=\"Page.handleShelvesClick()\" >My Books</a> > Settings and Download the books databases you want.<br>Once done, reload this page.<br>If you have already downloaded the book databases, then you will need to rebuild your local DB to fix this issue. Try this: 1) Drag the zero that is on the top right to the left<br>2) Click the 'Rebuild' button in the database section<br>3) Once the rebuild process is done reload this page</p>"
            
            offset_query = "OFFSET #{100*window.searchResults.offset}"

        else if window.searchResults.search_type == 'shelves'
            window.searchResults.search_header = "My Books"
            window.searchResults.search_string = ''
            window.searchResults.search_type = 'shelves'
            window.searchResults.show_count = false
            Page.showing = 'shelves'
            offset_query = ""
            window.searchResults.offset = null

            if !window.searchResults.active_shelf?
                window.searchResults.active_shelf = 0

            if typeof(search_string) != "undefined" and search_string != ''
                window.searchResults.active_shelf = search_string
            else
                search_string = window.searchResults.active_shelf
            
            search_string = window.searchResults.shelves[search_string].books.join(", ").toString()
            where = " WHERE book.b_id in (#{search_string})"
            window.searchResults.nothing_found_error = "No books found! Add books to your shelves to see them in here."
        
            if window.searchResults.active_shelf == 2 #pending
                window.searchResults.nothing_found_error = "<p class=\"lead\">Books in this shelf are not yet on Antilibrary. <br>This shelf is monitored by our backend system and the books should soon be added to the database.<br> You will be notified when this happens.<br>Make sure you have downloaded the database where the books can be located (eg: english non-fiction)</p>"
                window.searchResults.count =  0
                window.searchResults.show_loading = false
                window.searchResults.no_results_found = true                
                
                return true




        #@log where
        window.searchResults.count = 0
        Page.cmd "dbQuery", ["""
            SELECT 
            book.b_id,
            book.t,
            book.p_id,
            book.p_y,
            book.l_c,
            book_by_author.b_id,
            book_by_author.a_id,
            author.a_id,
            book_metadata.b_id,
            book_metadata.n_p,
            book_metadata.i_u,
            book_metadata.a_r,
            publisher.p_id,
            publisher.n as publisher_name 
            FROM book
            JOIN book_by_author ON book.b_id = book_by_author.b_id
            JOIN author ON book_by_author.a_id = author.a_id
            JOIN book_metadata ON book.b_id = book_metadata.b_id
            JOIN publisher ON book.p_id = publisher.p_id
            #{where}
            #{offset_query}
            """], (res) => 
            
            if res.error or res.length == 0
                window.searchResults.show_loading = false
                window.searchResults.no_results_found = true   
                return false             

            #remove duplicated books (they happen because of files) - much faster than doing this in sql
            res = (value for _,value of new -> @[item.b_id] = item for item in res; @)

            window.searchResults.books = []

            setAuthor = (book,authors) =>
                book.authors_names = authors

            for book in res
                book.authors_names = 'loading...'
                Book.getAuthors(book,setAuthor)
                
                #replace cover url
                #book.i_u = book.i_u.replace("d.gr-assets.com","images.gr-assets.com")
                book.i_u = book.i_u.replace("#al_cf#","cloudfront.net/books")
                book.i_u = book.i_u.replace("#al_gra#","http://images.gr-assets.com/books")


            window.searchResults.books = res
            window.searchResults.show_loading = false
            
            if search_string
                window.searchResults.show_count = true
            window.searchResults.count = res.length
                

window.searchResults = new Vue({
    el: "#search-container",
    data: {
        books: [],
        authors_names: {},
        shelves: {},
        active_shelf: 0,
        search_string: '',
        search_header: 'loading...',
        count: 0,
        offset: 0,
        show_count: true,
        show_loading: false,
        no_results_found: false,
        nothing_found_error: "Nothing found!",
        search_type: 'latest',
        import_progress_label: '',
        import_progress_current_value: 1,
        import_progress_max_value: 100,
        import_action_label: 'Import books',
        import_action_disabled: false,
        settings: {},
        upload_added_books: [],
        data_file_path: '',
        ebook_upload_accepted_files: 'MOBI, AZW, AZW3, EPUB and PDF',
        #merger sites: lang, genre, addr
        book_hubs: {
            '1GHdSLFqXdtfp9G5gnFWugAsGzHciY9fTN': { #PT NON FICTION
                address: '1GHdSLFqXdtfp9G5gnFWugAsGzHciY9fTN',
                language_code: 'pt',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            },
            '13NCGaR5RnGUTFkUGxPQugdPmSSPfW4qJi': { #DE NON FICTION
                address: '13NCGaR5RnGUTFkUGxPQugdPmSSPfW4qJi',
                language_code: 'de',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            },
            '1EVMjepYij9LZMtLzChtCQP9VXWbfqNHvR': { #IT NON FICTION
                address: '1EVMjepYij9LZMtLzChtCQP9VXWbfqNHvR',
                language_code: 'it',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            },
            '13eh33YQw1tFUvLagNtCFMnyd2RJH4jPoe': { #SP NON FICTION
                address: '13eh33YQw1tFUvLagNtCFMnyd2RJH4jPoe',
                language_code: 'sp',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            },
            '1FMFmcqTsELodnwy5Lf4X8CLkgPtmMTNs8': { #FR NON FICTION
                address: '1FMFmcqTsELodnwy5Lf4X8CLkgPtmMTNs8',
                language_code: 'fr',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            },       
            '1KrGwPRtnn77MsL35LBpNTEvvUhoLhmevq': { #EN NON FICTION
                address: '1KrGwPRtnn77MsL35LBpNTEvvUhoLhmevq',
                language_code: 'en',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            },       
            '1BdLZTJkEjyQaBStg1XPHGEaMovHeqVcVk': { #ZH NON FICTION
                address: '1BdLZTJkEjyQaBStg1XPHGEaMovHeqVcVk',
                language_code: 'zh',
                btn_label: 'Download',
                btn_class: 'btn-outline-success'
            }
        }
    },
    methods: {
        get_language_name: (code) =>
            return get_language_name(code)

        get_file_status: (status) =>
            if status.search(/added/) == 0
                book_id = status.split('|')[1]
                return "<a href=\"/Antilibrary.bit/?view:#{book_id}\">Added</a>"

            else if status.search(/virus_scan_failed/) == 0
                return "<strong>Error:</strong> File marked as suspicious by virus scanner. Make sure your file is free from viruses by scanning it <a href=\"https://www.virustotal.com/\" target=\"_blank\">online</a>."

            else if status.search(/invalid_file_format/) == 0
                return "<strong>Error:</strong> Invalid file format. The file type you provided is not accepted (accepted types are #{window.searchResults.ebook_upload_accepted_files})"

            else if status.search(/goodreads_id_not_found/) == 0
                return "<strong>Error:</strong> Goodreads ID not found. The goodreads ID you provided doesn't exist."

            else if status.search(/invalid_ipfs_hash/) == 0
                return "<strong>Error:</strong> The IPFS hash provided is not valid."

            else if status.search(/ipfs_file_download_failed/) == 0
                return "<strong>Error:</strong> File download failed. Please make sure you leave your <a href=\"https://ipfs.io/docs/commands/#ipfs-daemon\" target=\"_blank\">ipfs daemon</a> running until the file is added to Antilibrary."

            else 
                return status
        
        get_file_goodreads_link: (goodreads_id) =>
            return "<a href=\"https://www.goodreads.com/book/show/#{goodreads_id}\" target=\"_blank\">#{goodreads_id}</a>"

    }
})

window.Search = new Search()