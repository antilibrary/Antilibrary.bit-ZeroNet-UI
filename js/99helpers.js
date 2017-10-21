function bytesToSize(bytes) {
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return 'n/a';
    var i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
    if (i == 0) return bytes + ' ' + sizes[i];
    return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + sizes[i];
};

function get_language_name(code) {
    if (code == 'en') return 'English';
    if (code == 'sp') return 'Spanish';
    if (code == 'it') return 'Italian';
    if (code == 'pt') return 'Portuguese';
    if (code == 'de') return 'German';
    if (code == 'fr') return 'French';
    if (code == 'zh') return 'Chinese';
};

$('[data-toggle="tooltip"]').tooltip();

$(function () {
  $('[data-toggle="popover"]').popover()
})

function convertSeedersHash(hash) {

    hash = hash.replace("ma","Antilibrary");
    hash = hash.replace("jr","jrp_seedbox");
    hash = hash.replace("to","totoro");
    hash = hash.replace("ky","kyle6492");

    hash = hash.replace("an","Anonymous");
    hash = hash.replace("tr","Anonymous");
    hash = hash.replace("my","Anonymous");
    hash = hash.replace("al","Anonymous");//
    hash = hash.replace("as","Anonymous");
    hash = hash.replace("ty","Anonymous");
    hash = hash.replace("kh","Anonymous");
    hash = hash.replace("13","Anonymous");
    hash = hash.replace("fe","Anonymous");

    hash = hash.replace(/,/g,", ");
    return hash;
}

//FIXME
function click() {
    setTimeout(function(){ 
    $('[data-toggle="tooltip"]').tooltip()
    $('[data-toggle="popover"]').popover()
    new Clipboard('#clippy')
    }, 1000);
}

