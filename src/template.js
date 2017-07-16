'use strict';

const AWS = require('aws-sdk'),
    Handlebars = require('handlebars'),
    log = require('./utils/log').getLogger(),
    S3 = new AWS.S3();

function getTemplate() {
    let bucket =  process.env.BUCKET_NAME;
    let key = process.env.TEMPLATE_FILENAME;
    let params = {Bucket: bucket, Key: key};

    return new Promise((resolve,reject) => {
        S3.getObject(params, (err, data) => {
            if (err) {
                return reject(err);
            }
            let template =  data.Body.toString();
            log.info('getTemplate', {'params':params,'template': template});
            return resolve(Handlebars.compile(template));
        });
    });
}

module.exports = {
    'getTemplate': getTemplate
};
