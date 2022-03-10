namespace Inprotech.Tests.Web.Configuration.Names
{
    public class NameRelationValidatorFacts
    {
        //public class NameRelationValidatorFixture : IFixture<NameRelationValidator>
        //{
        //    public NameRelationValidator Subject
        //    {
        //        get
        //        {
        //            return new NameRelationValidator(InMemoryDbContext.Current);
        //        }
        //    }

        //    public dynamic CreateData()
        //    {
        //       var nameRelation1 = new NameRelation("TE1", Fixture.String(), Fixture.String(),(decimal)NameRelationType.Default,true, 0).InDb();

        //        return new
        //        {
        //           nameRelation1
        //        };
        //    }
        //}

        //public class ValidateOnPostMethod : FactBase
        //{
        //    [Fact]
        //    public void ReturnsSuceesValidationResultWhenNameRelationDoesnotExist()
        //    {
        //        var f = new NameRelationValidatorFixture();

        //        f.CreateData();

        //        var nameRelation = new NameRelation("TE3", Fixture.String(), Fixture.String(), (decimal)NameRelationType.Default, true, 1);

        //        var result = f.Subject.ValidateOnPost(nameRelation);

        //        Assert.Equal(true, result.IsValid);
        //        Assert.Equal("success", result.Status);
        //    }

        //    [Fact]
        //    public void ReturnsFailureValidationResultWhenDuplicateCodeIsInserted()
        //    {
        //        var f = new NameRelationValidatorFixture();

        //        f.CreateData();

        //        var nameRelation = new NameRelation("TE1", Fixture.String(), Fixture.String(), (decimal)NameRelationType.Default, true, 2);

        //        var result = f.Subject.ValidateOnPost(nameRelation);

        //        Assert.Equal(false, result.IsValid);
        //        Assert.Equal("failed", result.Status);
        //        Assert.Equal("duplicateNameRelationDescription", result.ValidationMessages[0].ValidationMessage);
        //    }

        //    [Fact]
        //    public void ItShouldreturnProperMessageWhenMandatoryFieldNotProvided()
        //    {
        //        var f = new NameRelationValidatorFixture();
        //        f.CreateData();
        //        var nameRelation = new NameRelation(null, null, null, 0, true, 0);

        //        var result = f.Subject.ValidateOnPost(nameRelation);

        //        Assert.Equal(false, result.IsValid);
        //        Assert.Equal("failed", result.Status);
        //        Assert.Equal(ConfigurationResources.NameRelationCodeRequired, result.ValidationMessages[0].ValidationMessage);
        //        Assert.Equal(ConfigurationResources.NameRelationDescriptionRequired, result.ValidationMessages[1].ValidationMessage);
        //        Assert.Equal(ConfigurationResources.NameRelationReverseRelationRequired, result.ValidationMessages[2].ValidationMessage);
        //        Assert.Equal(ConfigurationResources.NameRelationAtleastOneOptionRequired, result.ValidationMessages[3].ValidationMessage);
        //    }
        //}

        //public class ValidateOnDeleteMethod : FactBase
        //{
        //    [Fact]
        //    public void ItShouldAlwaysReturnTrue()
        //    {
        //        var f = new NameRelationValidatorFixture();

        //        var result = f.Subject.ValidateOnDelete(f.CreateData().nameRelation1.Id);

        //        Assert.Equal(true, result.IsValid);
        //        Assert.Equal("success", result.Status);
        //    }

        //}
        //public class ValidateOnPutMethod : FactBase
        //{
        //    [Fact]
        //    public void ReturnsSuceesValidationResult()
        //    {
        //        var f = new NameRelationValidatorFixture();

        //        var nameRelation = (NameRelation)f.CreateData().nameRelation1;
        //        nameRelation.RelationDescription = Fixture.String("updated");
        //        nameRelation.ReverseDescription = Fixture.String("updated");

        //        var result = f.Subject.ValidateOnPut(f.CreateData().nameRelation1, nameRelation);

        //        Assert.Equal(true, result.IsValid);
        //        Assert.Equal("success", result.Status);
        //    }
        //}
    }
}