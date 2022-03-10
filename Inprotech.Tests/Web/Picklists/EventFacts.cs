using System;
using System.Reflection;
using Inprotech.Tests.Web.Picklists.ResponseShaping;
using Inprotech.Web.Picklists;
using Inprotech.Web.Picklists.ResponseShaping;
using Xunit;

namespace Inprotech.Tests.Web.Picklists
{
    public class EventFacts
    {
        readonly Type _subject = typeof(Event);

        [Fact]
        public void DisplaysFollowingFields()
        {
            Assert.Equal(new[] {"Key", "Code", "Value", "Alias", "MaxCycles", "Importance", "EventCategory", "EventGroup", "EventNotesGroup"},
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
            Assert.Equal(new[] {"Key", "Code", "Value", "Importance", "EventCategory", "EventGroup", "EventNotesGroup"},
                         _subject.SortableFields());
        }

        [Fact]
        public void TogglableFields()
        {
            Assert.Equal(new[] {"Key", "Code", "Alias", "MaxCycles", "Importance", "EventCategory", "EventGroup", "EventNotesGroup", "CurrentCycle"},
                         _subject.TogglableFields());
        }
    }
}