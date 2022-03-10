'use strict'
namespace Inprotech.Integration.PtoAccess {
    export interface ISponsorshipService {
        get();
        delete(id: Number);
        addOrUpdate(sponsorshipModel, isUpdate: boolean);
    }

    class SponsorshipService implements ISponsorshipService {
        constructor(private $http: ng.IHttpService) {
        }
        get = () => {
            return this.$http.get('api/ptoaccess/uspto/privatepair/sponsorships')
                .then(response => {
                    return response.data;
                });
        }

        delete = (id: Number) => {
            return this.$http.delete('api/ptoaccess/uspto/privatepair/sponsorships/' + id);
        }

        addOrUpdate = (sponsorshipModel, isUpdate: boolean) => {
            let url = 'api/ptoaccess/uspto/privatepair/sponsorships';
            if (isUpdate) {
                return this.$http.patch(url, sponsorshipModel);
            } else {
                return this.$http.post(url, sponsorshipModel);
            }
        };

        updateAccountSettings = (sponsorshipModel) => {
            let url = 'api/ptoaccess/uspto/privatepair/sponsorships/accountSettings';
            return (this.$http as any).patch(url, sponsorshipModel, {
                handlesError: true
            });
        };
    }

    angular.module('Inprotech.Integration.PtoAccess')
        .service('sponsorshipService', ['$http', 'url', SponsorshipService])
}