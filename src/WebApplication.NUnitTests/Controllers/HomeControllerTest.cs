using NUnit.Framework;

namespace WebApplication.Controllers
{
    [TestFixture]
    public class HomeControllerTest
    {
        [Test]
        public void Contact_WhenCalled_ShouldReturnAnActionResult()
        {
            var sut = new HomeController();

            var actual = sut.Contact();

            Assert.IsNotNull(actual);
            
        }
    }
}