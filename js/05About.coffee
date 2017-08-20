class About extends Class 

    @project_stats = new Vue({
        el: "#project-stats",
        data: {
            total_books: 'loading...',
            total_files: 'loading...',
            total_seeded: 'loading...',
            total_size: 'loading...'
        }
    })


    showAbout: ->

        Page.cmd "dbQuery", ["SELECT COUNT(*) as ct FROM book"], (ct) =>
            About.project_stats.total_books = ct[0]['ct']

        Page.cmd "dbQuery", ["SELECT COUNT(*) as ct FROM book_file"], (ct) => 
            About.project_stats.total_files = ct[0]['ct']

        Page.cmd "dbQuery", ["SELECT COUNT(*) as ct FROM book_file WHERE i_s is not null"], (ct) => 
            About.project_stats.total_seeded = ct[0]['ct']

        Page.cmd "dbQuery", ["SELECT SUM(fs) as s FROM book_file WHERE i_s is not null"], (ct) => 
            res = ct[0]['s']
            res = 0 if !res?
            About.project_stats.total_size = bytesToSize(res)
        


window.About = new About()