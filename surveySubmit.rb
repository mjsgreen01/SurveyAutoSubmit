require "capybara"
require "capybarista"
#require "JSON"

Capybara.ignore_hidden_elements = true
Capybara.configure do |config|
  config.default_wait_time = 2
end

if ARGV.size < 2
	puts "Program aborted - add as command-line arguments, a URL and number of times to test the survey"
	exit
end
surveyUrl = ARGV[0]
numberTests = ARGV[1].to_i


class SurveyFiller

	attr_accessor :session

	def initialize(session)
		@session = session
	end

	def goToLastPage(url)
		session.visit url
		begin
			while session.has_css?(".gform_body")
				begin
					if session.first(:css, ".gform_next_button")
						session.find(:css, '.gform_next_button').click
					elsif session.first(:css, "input[type='submit']")
						break
					end
				rescue
					
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
			sleep 3
		end
	end

	def inputFill
		allInputs = session.all(:css, 'input[type="text"], textarea', :visible => false)
		inputIdArray = allInputs.map {|c| c[:id]}
		times = inputIdArray.length
		timesToFill = rand(times*2).ceil
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
		session.execute_script("var emailLabel = jQuery('.gfield_contains_required label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('email') >= 0});
								emailid = emailLabel.parent().attr('id');
								jQuery('#'+emailid+' input').val('#{@randomString}'+'@MSsurveyBot.com').attr('value', '#{@randomString}'+'@MSsurveyBot.com'); ")
		# fill in zip code
		@randomString = (0...5).map { (48 + rand(9)).chr }.join
		session.execute_script("var zipLabel = jQuery('select').parent().parent().children('label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('zip') >= 0});
								zipid = zipLabel.parent().attr('id');
								jQuery('#'+zipid+' input').val('#{@randomString}').attr('value', '#{@randomString}'); ")
		# select options from country and state dropdowns
		session.execute_script("var countryLabel = jQuery('label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('country') >= 0});
								countryLabel.parent().addClass('country')
								var countryid = countryLabel.parent().attr('id');
								jQuery('#'+countryid+' select').prop('selectedIndex', 4);

								var stateLabel = jQuery('select').parent().parent().children('label').filter(function(){return jQuery(this).text().toLowerCase().indexOf('state') >= 0});
								stateLabel.parent().addClass('state')
								var stateid = stateLabel.parent().attr('id');
								jQuery('#'+stateid+' select').prop('selectedIndex', 4);")
		# make sure country and state values are two characters long
		if session.first(:css, ".country select").value.length != 2
			puts "warning: the country dropdown option's value is not two characters"
		end
		if session.first(:css, ".state select").value.length != 2
			puts "warning: the state dropdown option's value is not two characters"
		end

		# find first daf options and randomly select them
		dafInputs = session.all(:css, '.daf .gfield_radio li:first-child input', :visible => false)
		dafIdArray =  dafInputs.map {|c| c[:id]}
		if [0, 1].sample == 1
			dafIdArray.each do |d|
				@selectedDaf = d
				session.execute_script("jQuery('#'+'#{@selectedDaf}').prop('checked',true); ")
			end
		end

	end

end


session = Capybara::Session.new :selenium

surveyBot = SurveyFiller.new(session)

numberTests.times do
	# go to the last page and fill in random checkboxes
	checkboxes = surveyBot.goToLastPage(surveyUrl).checkboxIdArray
	surveyBot.checkboxFill(checkboxes)
	# fill in random radio buttons
	radios = surveyBot.radioIdArray
	surveyBot.radioFill(radios)
	# fill in random input fields
	surveyBot.inputFill
	# fill in all required input fields
	surveyBot.requiredInputFill
	surveyBot.surveySubmit
end


