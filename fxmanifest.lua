fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'sh-scripts <store.sh-scripts.com>'

data_file 'DLC_ITYP_REQUEST' 'stream/qua_osimhen_mask.ytyp'
shared_scripts {
    'cfg.lua',
    'utils.lua',
    'shared.lua',
}

client_script 'client.lua'

escrow_ignore {
    'cfg.lua',
    'utils.lua',
    'shared.lua',
}
