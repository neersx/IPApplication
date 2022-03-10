namespace inprotech.components.form {
    describe('inprotech.components.form.email', () => {
        'use strict';

        describe('initialise', () => {
            it('should configure email link with cc, subject, body', () => {
                let c = new EmailLinkController();
                c.model = {
                    recipientEmail: 'someone@myorg.com',
                    recipientCopiesTo: ['one@two.three.com'],
                    subject: 'Regarding abc',
                    body: 'Regarding abc body, it is awesome! I want more.'
                }
                c.$onChanges({
                    model: {
                        currentValue: c.model,
                        previousValue: undefined
                    }
                });
                expect(c.email).toBe('mailto:someone@myorg.com?cc=one@two.three.com&subject=Regarding%20abc&body=Regarding%20abc%20body%2C%20it%20is%20awesome!%20I%20want%20more.');
            });
            it('should configure email link with subject, body', () => {
                let c = new EmailLinkController();
                c.model = {
                    recipientEmail: 'someone@myorg.com',
                    recipientCopiesTo: [],
                    subject: 'Regarding abc',
                    body: 'Regarding abc body, it is awesome! I want more.'
                }
                c.$onChanges({
                    model: {
                        currentValue: c.model,
                        previousValue: undefined
                    }
                });
                expect(c.email).toBe('mailto:someone@myorg.com?subject=Regarding%20abc&body=Regarding%20abc%20body%2C%20it%20is%20awesome!%20I%20want%20more.');
            });
            it('should configure email link with multiple cc recipients', () => {
                let c = new EmailLinkController();
                c.model = {
                    recipientEmail: 'someone@myorg.com',
                    recipientCopiesTo: ['one@two.three.com', 'four@five.com'],
                    subject: 'Regarding abc',
                    body: 'Regarding abc body, it is awesome! I want more.'
                }
                c.$onChanges({
                    model: {
                        currentValue: c.model,
                        previousValue: undefined
                    }
                });
                expect(c.email).toBe('mailto:someone@myorg.com?cc=one@two.three.com;four@five.com&subject=Regarding%20abc&body=Regarding%20abc%20body%2C%20it%20is%20awesome!%20I%20want%20more.');
            });
        });
    });
}