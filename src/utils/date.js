'use strict';

function getWeekOfTheYear() {
    let now = new Date();
    let firstOfJanuary = new Date(now.getFullYear(),0,1);
    return Math.ceil((((now - firstOfJanuary) / 86400000) + firstOfJanuary.getDay())/7);
}

module.exports = {
    'getWeekOfTheYear': getWeekOfTheYear
};
