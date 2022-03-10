using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Components.Security.SingleSignOn;
using InprotechKaizen.Model.Security;
using Xunit;

namespace Inprotech.Tests.Model.Components.Security.SingleSignOn
{
    public class SsoUserIdentifierFacts
    {
        public class TryFindUserMethod : FactBase
        {
            public TryFindUserMethod()
            {
                _subject = new SsoUserIdentifier(Db);
            }

            readonly SsoUserIdentifier _subject;

            [Fact]
            public void FindUserReturnsNullIfGukNotFound()
            {
                User user;
                var result = _subject.TryFindUser(Guid.NewGuid(), out user);
                Assert.Null(user);
                Assert.False(result);
            }

            [Fact]
            public void FindUserReturnsUserAssociatedWithGuk()
            {
                var guk = Guid.NewGuid();
                var user = new User("SomeUser", false) {Guk = guk.ToString()}.In(Db);

                User userResult;

                Assert.True(_subject.TryFindUser(guk, out userResult));
                Assert.Equal(user, userResult);
            }

            [Fact]
            public void FindUserThrowsIfMultipleUsersHaveSameGuk()
            {
                var guk = Guid.NewGuid();
                new User("SomeUser", false) {Guk = guk.ToString()}.In(Db);
                new User("SomeUser2", false) {Guk = guk.ToString()}.In(Db);

                Assert.Throws<InvalidOperationException>(() => { _subject.TryFindUser(guk, out _); });
            }
        }

        public class EnforceEmailValidityMethod : FactBase
        {
            public EnforceEmailValidityMethod()
            {
                _subject = new SsoUserIdentifier(Db);
            }

            readonly SsoUserIdentifier _subject;

            [Fact]
            public void ReturnsTrueIfEmailIdMatches()
            {
                var nameArya = new NameBuilder(Db)
                    {
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "Arya.Stark@got.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                var user = new User("Arya", false) {Name = nameArya, Guk = "someguk"}.In(Db);

                Assert.True(_subject.EnforceEmailValidity("Arya.Stark@got.com", user, out var result));
                Assert.Equal(SsoUserLinkResultType.Success, result);
                Assert.NotNull(Db.Set<User>().SingleOrDefault(_ => _.Guk == "someguk"));
            }

            [Fact]
            public void UnlinksGukIfEmailIdAssignedToMultiple()
            {
                var nameJon = new NameBuilder(Db)
                    {
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "jon@got.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                var user = new User("Snow", false) {Name = nameJon, Guk = "someguk"}.In(Db);
                new User("Targaryen", false) {Name = nameJon}.In(Db);

                Assert.False(_subject.EnforceEmailValidity("jon@got.com", user, out var result));
                Assert.Equal(SsoUserLinkResultType.NonUniqueEmail, result);
                Assert.Null(Db.Set<User>().SingleOrDefault(_ => _.Guk == "someguk"));
            }

            [Fact]
            public void UnlinksGukIfEmailIdDoesNotMatch()
            {
                var nameArya = new NameBuilder(Db)
                    {
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "Cat.Stark@got.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                var user = new User("Arya", false) {Name = nameArya, Guk = "someguk"}.In(Db);

                Assert.False(_subject.EnforceEmailValidity("Arya.Stark@got.com", user, out var result));
                Assert.Equal(SsoUserLinkResultType.NoMatchingInprotechUser, result);
                Assert.Null(Db.Set<User>().SingleOrDefault(_ => _.Guk == "someguk"));
            }
        }

        public class TryLinkUserAutoMethod : FactBase
        {
            public TryLinkUserAutoMethod()
            {
                _subject = new SsoUserIdentifier(Db);
            }

            readonly SsoUserIdentifier _subject;
            readonly Guid _guk = Guid.NewGuid();

            const string FirstName = "John";
            const string LastName = "Snow";

            [Fact]
            public void TryLinkUserReturnsNullIfMultipleUsersFound()
            {
                var name1 = new NameBuilder(Db)
                    {
                        FirstName = FirstName,
                        LastName = LastName,
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "j.s@xyz.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                var name2 = new NameBuilder(Db)
                    {
                        FirstName = FirstName,
                        LastName = LastName,
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "j.s@xyz.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                new User("john1", false) {Name = name1}.In(Db);
                new User("john2", true) {Name = name2}.In(Db);

                var identity = new SsoIdentity
                {
                    Email = "j.s@xyz.com",
                    FirstName = FirstName,
                    LastName = LastName,
                    Guk = _guk
                };

                User userResult;
                Assert.False(_subject.TryLinkUserAuto(identity, out userResult, out var result));
                Assert.Equal(SsoUserLinkResultType.NonUniqueEmail, result);
                Assert.Null(userResult);
                Assert.False(Db.Set<User>().Any(_ => _.Guk == _guk.ToString()));
            }

            [Fact]
            public void TryLinkUserReturnsNullIfNoUserFound()
            {
                var name1 = new NameBuilder(Db)
                    {
                        FirstName = FirstName,
                        LastName = LastName,
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "j.s@xyz.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                var name2 = new NameBuilder(Db)
                    {
                        FirstName = FirstName,
                        LastName = LastName,
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "Unique.s@xyz.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                new User("john1", false) {Name = name1}.In(Db);
                new User("john2", true) {Name = name2}.In(Db);

                var identity = new SsoIdentity
                {
                    Email = "ww@xyz.com",
                    FirstName = FirstName,
                    LastName = LastName,
                    Guk = _guk
                };

                User userResult;

                Assert.False(_subject.TryLinkUserAuto(identity, out userResult, out var result));
                Assert.Equal(SsoUserLinkResultType.NoMatchingInprotechUser, result);
                Assert.Null(userResult);
                Assert.False(Db.Set<User>().Any(_ => _.Guk == _guk.ToString()));
            }

            [Fact]
            public void TryLinkUserReturnsUserIfUnique()
            {
                var name1 = new NameBuilder(Db)
                    {
                        FirstName = FirstName,
                        LastName = LastName,
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "j.s@xyz.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                var name2 = new NameBuilder(Db)
                    {
                        FirstName = FirstName,
                        LastName = LastName,
                        Email = new TelecommunicationBuilder
                            {
                                TelecomNumber = "Unique.s@xyz.com"
                            }.Build()
                             .In(Db)
                    }.Build()
                     .In(Db);

                new User("john1", false) {Name = name1}.In(Db);
                new User("john2", true) {Name = name2}.In(Db);

                var identity = new SsoIdentity
                {
                    Email = "Unique.s@xyz.com",
                    FirstName = Fixture.String(),
                    LastName = Fixture.String(),
                    Guk = _guk
                };

                User userResult;

                Assert.True(_subject.TryLinkUserAuto(identity, out userResult, out var result));
                Assert.Equal(SsoUserLinkResultType.Success, result);
                Assert.NotNull(userResult);
                Assert.True(Db.Set<User>().Any(_ => _.Guk == _guk.ToString()));
            }
        }
    }
}