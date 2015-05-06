require "capybara"
require "capybarista"
require "JSON"

Capybara.ignore_hidden_elements = true
Capybara.configure do |config|
  config.default_wait_time = 4
end



class SurveyFiller

	attr_accessor :session

	def initialize(session)
		@session = session
	end

	def goToLastPage(url)
		session.visit url
		begin
			while !session.first(:css, ".gform_next_button").nil?
				if session.first(:css, ".gform_next_button")
					session.find(:css, '.gform_next_button').click
				end

			end
		rescue
			puts "goToLastPage method error - most likely nothing to worry about"
		end
		return self
	end

	def checkboxIdArray
		allCheckboxes = session.all(:css, ".gfield_checkbox input", :visible => false)
		return allCheckboxes.map {|c| c[:id]}
	end

	def checkboxFill(checkboxArray)
		
		times = checkboxArray.length
		timesToCheck = rand(times*2)
		timesToCheck.times do |i|
			@sampledID = checkboxArray.sample
			session.execute_script("jQuery('#'+'#{@sampledID}').prop('checked',true); ")
		end
		
	end

	def radioIdArray
		allRadios = session.all(:css, ".gfield_radio input", :visible => false)
		return allRadios.map {|c| c[:id]}
	end

	def radioFill(radioArray)
		times = radioArray.length
		timesToCheck = rand(times)
		timesToCheck.times do |i|
			@sampledID = radioArray.sample
			session.execute_script("jQuery('#'+'#{@sampledID}').prop('checked',true); ")
		end
	end


	def surveySubmit
		if session.first(:css, "input[type='submit']")
			session.find(:css, "input[type='submit']").click
			sleep 2
		end
	end

	def inputFill
		allInputs = session.all(:css, 'input[type="text"], textarea, select', :visible => false)
		inputIdArray = allInputs.map {|c| c[:id]}
		times = inputIdArray.length
		timesToFill = rand(times*2)
		timesToFill.times do |i|
			@sampledID = inputIdArray.sample
			@randomString = (0...8).map { (65 + rand(26)).chr }.join
			session.execute_script("jQuery('#'+'#{@sampledID}').val('#{@randomString}').attr('value', '#{@randomString}'); ")
		end
	end
	def requiredInputFill
		requiredInputs = session.all(:css, '.gfield_contains_required input', :visible => false)
		inputIdArray = requiredInputs.map {|c| c[:id]}
		inputIdArray.each{|i|
			@sampledID = i
			@randomString = (0...8).map { (65 + rand(26)).chr }.join
			session.execute_script("jQuery('#'+'#{@sampledID}').val('#{@randomString}').attr('value', '#{@randomString}'); ")
		}
		# fill in email address
		@randomString = (0...8).map { (65 + rand(26)).chr }.join
		session.execute_script("var emailLabel = jQuery('.gfield_contains_required label').filter(function(){return jQuery(this).text() == 'Email*'});
								emailid = emailLabel.parent().attr('id');
								jQuery('#'+emailid+' input').val('#{@randomString}'+'@MSsurveyBot.com').attr('value', '#{@randomString}'+'@MSsurveyBot.com'); ")
	end

end


session = Capybara::Session.new :selenium

surveyBot = SurveyFiller.new(session)

# go to the last page and fill in random checkboxes
checkboxes = surveyBot.goToLastPage("http://audubon-giftmaker-wpengine-com.giftmaker.staging.wpengine.com/").checkboxIdArray
surveyBot.checkboxFill(checkboxes)
# fill in random radio buttons
radios = surveyBot.radioIdArray
surveyBot.radioFill(radios)
# fill in random input fields
surveyBot.inputFill
# fill in all required input fields
surveyBot.requiredInputFill
surveyBot.surveySubmit



