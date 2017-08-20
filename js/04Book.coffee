class Book extends Class 

    getAuthors: (book,cb) =>
        Page.cmd "dbQuery", ["SELECT * FROM author as a, book_by_author as ba WHERE ba.b_id = #{book.b_id} and a.a_id = ba.a_id GROUP BY ba.a_id"], (res) =>
            authors = []
            for author in res
                authors.push author.n 
            cb(book,authors.join(", "))

    showBook: (b_id) ->

        Page.cmd "dbQuery", ["""
            SELECT * FROM book as b, book_metadata as bm, publisher as p
            WHERE 
            b.b_id = #{b_id} and 
            b.p_id = p.p_id and 
            bm.b_id = b.b_id
            GROUP BY b.b_id
            """], (res) =>

            if res.length == 0
                window.alert.msg = "<strong>Book not found in your databases!</strong><br>The book you are trying to view is not in your local databases.<br>Maybe you have just downloaded the site? If so, please go to <a href=\"#\" onclick=\"Page.handleShelvesClick()\" >My Books</a> > Settings and Download the books databases you want.<br><br>Once done, reload this page."
                window.alert.visible = true
                $("#book-modal").modal('hide')
                return false
            

            #attach authors vue element
            res[0].authors_names = 'Loading...'

            window.bookModal.book = res[0]
            
            @log "Showing book: #{window.bookModal.book.t}"
            
            setAuthor = (book,authors) =>
                book.authors_names = authors

            @getAuthors(window.bookModal.book,setAuthor)

            months = ['-','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
            window.bookModal.book.month_name = months[window.bookModal.book.p_m]

            window.bookModal.book.p = window.bookModal.book.n
            window.bookModal.book.language = get_language_name(window.bookModal.book.l_c)

            window.bookModal.book.direct_link = "/Antilibrary.bit/?view:" + window.bookModal.book.b_id
            window.bookModal.book.goodreads_link = "https://www.goodreads.com/book/show/" + window.bookModal.book.g_id
            window.bookModal.book.share_zerome_plus_link = "/1Lj1oPcN7oZQL8HkS5KbkzQuKqs42zQWY6/?SetPost&body=[" + window.bookModal.book.t + "](/Antilibrary.bit/?view:" + window.bookModal.book.b_id + ")"

            $("#book-modal").modal('show')

            if window.bookModal.book.d
                strData = atob(window.bookModal.book.d)
                charData = strData.split('').map((x) -> x.charCodeAt 0)
                binData = new Uint8Array(charData)
                data = pako.inflate(binData)
                strData = String.fromCharCode.apply(null, new Uint16Array(data))
                window.bookModal.book.d =  utf8.decode(strData)

            #replace cover url
            #window.bookModal.book.i_u = window.bookModal.book.i_u.replace("d.gr-assets.com","images.gr-assets.com")
            window.bookModal.book.i_u = window.bookModal.book.i_u.replace("#al_cf#","cloudfront.net/books")
            window.bookModal.book.i_u = window.bookModal.book.i_u.replace("#al_gra#","http://images.gr-assets.com/books")

            window.bookModal.files = []
            @showFilesInModal()

            #replace url
            url = window.location.search.substring(1).replace(/.*/,"view:#{window.bookModal.book.b_id}")
            Page.cmd "wrapperReplaceState", ["", "", url]

            $('#book-modal').on 'hide.bs.modal', =>
                url = window.location.search.substring(1).replace(/.*/,"")
                Page.cmd "wrapperReplaceState", ["", "", url]



    showFilesInModal: () =>
        @log "Loading files for: #{window.bookModal.book.b_id}"
        window.bookModal.files_loading = true
        
        Page.cmd "dbQuery", ["""
            SELECT * FROM book as b, book_metadata as bm, publisher as p, book_file as bf
            WHERE 
            b.b_id = #{window.bookModal.book.b_id} and 
            b.p_id = p.p_id and 
            bm.b_id = b.b_id and
            bf.b_id = b.b_id
            GROUP BY md5
            ORDER BY i_h DESC
            """], (res) =>

                window.bookModal.files = []
                for file in res
                    file.status_tag_label = "None"
                    file.status_tag_class = "tag-default"
                    file.status_help_text = ''
                    file.disabled = false
                    window.bookModal.files.push file

                window.bookModal.files = res


                if window.bookModal.files.length == 0
                    @log "No files found!"
                    window.bookModal.files_loading = false
                    return

                @log "#{window.bookModal.files.length} files found!"
                title = window.bookModal.book.t.replace /[^0-9A-Za-z,.()\-]/g, '_'
                authors = window.bookModal.book.authors_names.replace /[^0-9A-Za-z,.\-]/g, '_'
                for file in window.bookModal.files
                    file.filename = authors + "-" + title + "." + file.ft
                    if file.i_h
                        file.ipfs_link = file.i_h 

                    file.size = bytesToSize(file.fs)

                    #fix issue when seeds == 0
                    if file.i_s
                        if file.i_s.length == 1
                            file.i_s = false 


                    file.disabled = false
                    if !file.i_s
                        file.status_tag_label = "Offline"
                        file.status_tag_class = "tag-danger"

                        if User.data.requests?
                            if file.b_f_id in User.data.requests
                                console.log "Book #{file.b_f_id} already requested!"
                                file.status_tag_label = "Requested"
                                file.status_tag_class = "tag-default"
                                file.status_help_text = "Please wait while we post this file online. This may take from 1h to 24h."
                                file.disabled = true
                    else
                        file.status_tag_label = "Online"
                        file.status_tag_class = "tag-success"
                        file.seeders = convertSeedersHash(file.i_s) 
        
                    window.bookModal.files_loading = false

                    #FIXME
                    click()



window.bookModal = new Vue({
    el: "#book-modal",
    data: {
        book: {},
        files: [],
        files_loading: false,
        shelves: null
    },
    methods: {
        getFirstShelf: (b_id,ret_type='name') =>
        #FIXME: too inefficient 
            if User.data
                for index of User.data.shelves
                    #console.log "Checking #{User.data.shelves[index].name} - #{index}"
                    if b_id in User.data.shelves[index].books
                        return index if ret_type == 'index'
                        return User.data.shelves[index].name if ret_type == 'name'
                return 0
        
        InShelf: () =>
            shelves = []
            if User.data
                for shelf in User.data.shelves
                    if shelf.name != "Pending"
                        shelf.index = User.data.shelves.indexOf(shelf)
                        shelves.push shelf

                return shelves
    }
})
window.Book = new Book()