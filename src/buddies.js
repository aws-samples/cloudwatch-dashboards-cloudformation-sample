'use strict';

const log = require('./utils/log').getLogger();

function getPairs(names, weekNumber) {
    let increment = (weekNumber % names.length) + 1;
    let pairs = names.map((name, index, names) => {
        let assigneeIndex = (index + increment) % names.length;
        let assignee = names[assigneeIndex];
        return {
            'assignor': name,
            'assignee': assignee
        };
    });

    log.info('getPairs',{'pairs': pairs});
    return pairs;
}

module.exports = {
    'getPairs': getPairs
};
