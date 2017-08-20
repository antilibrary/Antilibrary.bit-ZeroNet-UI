class Antilibrary extends ZeroFrame

    init: ->
        @log "inited!"

        #attach search input enter
        $("#search-string").on "keydown", (e) =>
            if e.keyCode == 13
                Search.executeSearch('keywords',$("#search-string").val().trim()) 
        
        @userDB = '19sZZmJPz1hADwitEs2XT6U46uHLGbHqKi'
        


    onOpenWebsocket: (e) =>
        #Page.cmd "certSelect", [["zeroid.bit"]]
        #return false

        Page.cmd "siteInfo", {}, (site_info) =>
            @site_info = site_info
            User.loadSettingsFromFile(@routeUrl)

        @checkDBS()


    onRequest: (cmd, params) ->
        @log cmd, params

        if cmd == "setSiteInfo" # Site updated
            @log "Refreshing merger sites..."
            @checkDBS()


    checkDBS: () =>
        @cmd "mergerSiteList", {}, (merged_sites) =>
            @log "Merger sites added: ",merged_sites
            for hub of window.searchResults.book_hubs
                window.searchResults.book_hubs[hub].btn_label = 'Download'
                window.searchResults.book_hubs[hub].btn_class = 'btn-outline-success'
                for merger of merged_sites
                    if merger == hub
                        window.searchResults.book_hubs[hub].btn_label = 'Delete'
                        window.searchResults.book_hubs[hub].btn_class = 'btn-outline-danger'

    addDB: (db) =>
        Page.cmd "siteInfo", {}, (site_info) =>
            @site_info = site_info

            @cmd "mergerSiteList", {}, (merged_sites) =>
                @log merged_sites
      
                if "Merger:Antilibrary" in @site_info.settings.permissions 

                    if not merged_sites[db]
                        @cmd "mergerSiteAdd", db, =>
                            window.searchResults.book_hubs[db].btn_class = "btn-outline-secondary"
                            window.searchResults.book_hubs[db].btn_label = "<i class=\"fa fa-spinner fa-pulse fa-fw\"></i> Please wait..."

                            #add user db
                            if not merged_sites[Page.userDB]
                                Page.cmd "mergerSiteAdd", Page.userDB
                    else
                        @cmd "wrapperConfirm", ["Are you sure you sure?", "Delete"], (confirmed) =>
                            if confirmed
                                #@cmd "siteDelete", {"address": db}
                                @cmd "mergerSiteDelete", db, =>
                                    window.searchResults.book_hubs[db].btn_class = "btn-outline-secondary"
                                    window.searchResults.book_hubs[db].btn_label = "<i class=\"fa fa-spinner fa-pulse fa-fw\"></i> Please wait..."

                else
                    @cmd "wrapperNotification", ["info", "Please, authorize the merger site and try again.", 4000]
                    @cmd "wrapperPermissionAdd", "Merger:Antilibrary", (res) =>
                        @addDB(db)
                    return false
                
            

    handleHomeClick: (e) =>
        url = window.location.search.substring(1).replace(/.*/,"")
        Page.cmd "wrapperReplaceState", ["", "", url]
        window.searchResults.offset = 0
        @viewPage('search-container')
        $("#search-string").val('')
        Search.executeSearch('latest',null,0)
        User.checkRequests()

    handleAboutClick: (e) =>
        Page.viewPage('about-container')
        About.showAbout()

    handleShelvesClick: () ->
        @viewPage('search-container')
        User.checkPendingShelf()
        Search.executeSearch('shelves')

    handleSearchClick: (e) =>
        Search.executeSearch('keywords',$("#search-string").val().trim()) 


    routeUrl: () =>
        url = window.location.search.substring(1)

        if url.match /view:([0-9]+)/
            match = url.match /view:([0-9]+)/
            Book.showBook match[1],null

        #show latest
        @viewPage('search-container')
        Search.executeSearch()
        User.checkRequests()



    viewPage: (page='') ->
        window.alert.visible = false
        linkName = page.split('-')[0]
        
        @log "View Page: ##{page}"
        for p in ['search-container','about-container']
            $("##{p}").hide()
            linkRemoveActive = p.split('-')[0]
            $("##{linkRemoveActive}-link").parent().removeClass('active')

        if page
            $("##{page}").removeClass('invisible')
            $("##{page}").show()
            $("##{linkName}-link").parent("li").addClass('active')
            @showing = page
            



window.alert = new Vue({
    el: '#site_alert',
    data: {
        visible: false,
        msg: '',
        class_type: 'alert-danger'
    }
    })


window.Page = new Antilibrary()
