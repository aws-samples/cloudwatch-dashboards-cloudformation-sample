'use strict';

const log = require('lambda-log');
let logger;

module.exports = {
    'getLogger': (event) => {
        if (!logger) {
            if (event) {
                log.config.meta.event = event;
                if (event.env) {
                    log.config.tags.push(event.env);                    
                }
            }
            log.config.silent = (process.env.NODE_ENV === 'test');
            logger = log;
        }
        return logger;
    }
};
