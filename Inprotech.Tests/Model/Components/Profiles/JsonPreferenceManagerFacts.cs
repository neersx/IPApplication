using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Components.Profiles;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Profiles
{
    public class JsonPreferenceManagerFacts
    {
        IUserPreferenceManager _preferenceManager;

        IJsonPreferenceManager GetSubject()
        {
            _preferenceManager = Substitute.For<IUserPreferenceManager>();
            return new JsonPreferenceManager(_preferenceManager);
        }
        
        [Fact]
        public void ThrowsExceptionToGetNonJsonSetting()
        {
            var f = GetSubject();
            Assert.Throws<ArgumentException>(() => f.Get(1, 0));
        }

        [Fact]
        public void CallsPrefManagerToGetJsonSettings()
        {
            var output = new JObject();
            var f = GetSubject();
            _preferenceManager.GetPreference<string>(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(output.ToString());
            var result = f.Get(1, KnownSettingIds.WorkingHours);

            Assert.Equal(output, result);
        }

        [Fact]
        public void ThrowsExceptionOnSetOfNonJsonSetting()
        {
            var input = new JObject();
            var f = GetSubject();
            Assert.Throws<ArgumentException>(() => f.Set(1, 0, input));
        }

        [Fact]
        public void CallsSetIfJsonSetting()
        {
            var input = new JObject();
            var f = GetSubject();

            f.Set(1, KnownSettingIds.WorkingHours, input);
            _preferenceManager.Received(1).SetPreference(1, KnownSettingIds.WorkingHours, input.ToString());
        }

        [Fact]
        public void ThrowsExceptionToResetNonJsonSetting()
        {
            var f = GetSubject();
            Assert.Throws<ArgumentException>(() => f.Reset(1, 0));
        }

        [Fact]
        public void CallsResetIfJsonSetting()
        {
            var f = GetSubject();

            f.Reset(1, KnownSettingIds.WorkingHours);
            _preferenceManager.Received(1).ResetUserPreferences(1, Arg.Is<int[]>(_ => _.SequenceEqual(new[] { KnownSettingIds.WorkingHours })));
        }
    }
}