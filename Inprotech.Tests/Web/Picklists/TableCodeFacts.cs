using System;
using System.Reflection;
using Inprotech.Tests.Web.Picklists.ResponseShaping;
using Inprotech.Web.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class TableCodeFacts
    {
        readonly Type _subject = typeof(TableCodePicklistController.TableCodePicklistItem);

        [Fact]
        public void DisplaysFollowingFields()
        {
            Assert.Equal(new[] {"Code", "Value"},
                         _subject.DisplayableFields());
        }

        [Fact]
        public void PicklistCodeIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Code")
                           .GetCustomAttribute<PicklistCodeAttribute>());
        }

        [Fact]
        public void PicklistDescriptionIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Value")
                           .GetCustomAttribute<PicklistDescriptionAttribute>());
        }

        [Fact]
        public void PicklistKeyIsDefined()
        {
            Assert.NotNull(_subject
                           .GetProperty("Key")
                           .GetCustomAttribute<PicklistKeyAttribute>());
        }

        [Fact]
        public void SortableFields()
        {
            Assert.Equal(new[] {"Code", "Value"},
                         _subject.SortableFields());
        }

        [Fact]
        public void TogglableFields()
        {
            Assert.Empty(_subject.TogglableFields());
        }
    }
}