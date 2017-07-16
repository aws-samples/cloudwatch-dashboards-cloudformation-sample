'use strict';

const expect = require('chai').expect,
    buddies = require('../src/buddies.js');

describe('Buddies', () => {
    describe('should get valid pairs', () => {
        it('when names length is equal to week number', () => {
            let names = ['a','b','c'];
            let pairs = buddies.getPairs(names, names.length);
            expect(pairs.length).to.be.eql(names.length);
            expect(pairs[0].assignor).to.be.eql('a');
            expect(pairs[0].assignee).to.be.eql('b');
            expect(pairs[1].assignor).to.be.eql('b');
            expect(pairs[1].assignee).to.be.eql('c');
            expect(pairs[2].assignor).to.be.eql('c');
            expect(pairs[2].assignee).to.be.eql('a');
        });

        it('when the week number is a multiple of names length', () => {
            let names = ['a','b','c'];
            let pairs = buddies.getPairs(names, names.length * 2);
            expect(pairs.length).to.be.eql(names.length);
            expect(pairs[0].assignor).to.be.eql('a');
            expect(pairs[0].assignee).to.be.eql('b');
            expect(pairs[1].assignor).to.be.eql('b');
            expect(pairs[1].assignee).to.be.eql('c');
            expect(pairs[2].assignor).to.be.eql('c');
            expect(pairs[2].assignee).to.be.eql('a');
        });

        it('when the week number is a power of names length', () => {
            let names = ['a','b','c'];
            let pairs = buddies.getPairs(names, names.length * names.length);
            expect(pairs.length).to.be.eql(names.length);
            expect(pairs[0].assignor).to.be.eql('a');
            expect(pairs[0].assignee).to.be.eql('b');
            expect(pairs[1].assignor).to.be.eql('b');
            expect(pairs[1].assignee).to.be.eql('c');
            expect(pairs[2].assignor).to.be.eql('c');
            expect(pairs[2].assignee).to.be.eql('a');
        });
    });
});
