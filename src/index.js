'use strict';

const AWS = require('aws-sdk'),
    buddies = require('./buddies.js'),
    SNS = new AWS.SNS(),
    template = require('./template.js'),
    utilsDate = require('./utils/date.js'),
    utilsLog = require('./utils/log.js');

exports.handler = function(event, context, callback) {
    let log = utilsLog.getLogger(event);
    log.info('ENV', { 'environment': process.env });

    let names =  process.env.TEAM_MEMBER_NAMES.split(';'),
        topicArn = process.env.SNS_TOPIC_ARN,
        weekNumber = utilsDate.getWeekOfTheYear();

    template.getTemplate()
    .then((template) => {
        let codeBuddies = buddies.getPairs(names, weekNumber);

        let snsPromise = SNS.publish({
            Message: template({
                'codeBuddies': codeBuddies,
                'weekNumber': weekNumber
            }),
            TopicArn: topicArn
        }).promise();

        snsPromise
            .then(() => {
                log.info('Notification sent succefully');
                callback(null, 'SENT');
            })
            .catch((e) => {
                log.error('Error sending notification', e);
                callback(e);
            });
    })
    .catch((e) => {
        log.error('Error loading email template Did you forget to run `update-template` command?', e);
        callback(e);
    });
};
